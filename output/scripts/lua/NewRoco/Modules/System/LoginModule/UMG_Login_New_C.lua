local LoginModuleEvent = reload("NewRoco.Modules.System.LoginModule.LoginModuleEvent")
local LoginUtils = require("NewRoco.Modules.System.LoginModule.LoginUtils")
local LoginEnum = require("NewRoco.Modes.LoginMode.LoginEnum")
local DialogContext = require("NewRoco.Modules.System.TipsModule.DialogContext")
local UpdateUIModuleEvent = require("NewRoco.Modules.System.UpdateUIModule.UpdateUIModuleEvent")
local CommonUtils = require("NewRoco.Utils.CommonUtils")
local UMG_Login_New_C = _G.NRCPanelBase:Extend("UMG_Login_New_C")

function UMG_Login_New_C:OnConstruct()
  self.VideoMap = {}
  self.VideoMap[UEPath.LOGIN_CLOUD_LOOP] = self.videoAsset1
  self.bDownloading = false
  self.TargetPercent = 0
  self.AnimationMap = {}
  self.AnimationMap.LoginIn = self.LoginIn
  self.AnimationMap.LoginOut = self.LoginOut
  self.AnimationMap.HideLogo = self.LogoAnimation
  self.BtnList = {
    self.UMG_Login_Register.Btn_Announcement,
    self.UMG_Login_Register.Btn_Repair,
    self.UMG_Login_Register.Btn_WriteOff,
    self.UMG_Login_Register.DownloadBtn,
    self.UMG_Login_Register.Btn_DropOut,
    self.UMG_Login_Register.Btn_AutoGame,
    self.UMG_Login_Register.Btn_Repair_1,
    self.UMG_Login_Register.Btn_Suspend,
    self.UMG_Login_Register.Btn_Suspend_1,
    self.UMG_Login_Register.Btn_ScanLogin,
    self.UMG_Login_Register.Btn_CustomerService,
    self.UMG_Login_Register.Btn_CustomerService_1
  }
  self.CanvasMap = {}
  self.CanvasMap[LoginEnum.CanvasNames.NRCLoginPanel] = LoginUtils.NewCanvasInfo(self.LoginCanvas, "LoginIn", "LoginOut")
  self.CanvasMap[LoginEnum.CanvasNames.NRCLogoPanel] = LoginUtils.NewCanvasInfo(self.LogoCanvas, nil, "HideLogo")
  self.CanvasMap[LoginEnum.CanvasNames.NRCEnterPanel] = LoginUtils.NewCanvasInfo(self.EnterCanvas)
  self.CanvasMap[LoginEnum.CanvasNames.NRCBackPanel] = LoginUtils.NewCanvasInfo(self.BackCanvas)
  self.CanvasMap[LoginEnum.CanvasNames.AccountPanel] = LoginUtils.NewCanvasInfo(self.UMG_Login_Register.DownloadCompletes)
  self.CanvasMap[LoginEnum.CanvasNames.CanDownloadPanel] = LoginUtils.NewCanvasInfo(self.UMG_Login_Register.Accomplish)
  self.CanvasMap[LoginEnum.CanvasNames.CompliancePanel] = LoginUtils.NewCanvasInfo(self.UMG_Login_Register.Compliance)
  self.CanvasMap[LoginEnum.CanvasNames.AccountSwitchPanel] = LoginUtils.NewCanvasInfo(self.UMG_Login_Register.Btn_WriteOff)
  self.CanvasMap[LoginEnum.CanvasNames.WebCameraPanel] = LoginUtils.NewCanvasInfo(self.CameraCanvas)
  self.CanvasMap[LoginEnum.CanvasNames.AnnouncementPanel] = LoginUtils.NewCanvasInfo(self.UMG_Login_Register.Btn_Announcement)
  self.CanvasMap[LoginEnum.CanvasNames.RepairToolsPanel] = LoginUtils.NewCanvasInfo(self.UMG_Login_Register.Btn_Repair)
  self.CanvasMap[LoginEnum.CanvasNames.UpdateRepairToolsPanel] = LoginUtils.NewCanvasInfo(self.UMG_Login_Register.Btn_Repair_Update)
  self.CanvasMap[LoginEnum.CanvasNames.ExitGamePanel] = LoginUtils.NewCanvasInfo(self.UMG_Login_Register.Btn_DropOut)
  self.CanvasMap[LoginEnum.CanvasNames.UpdateProgressPanel] = LoginUtils.NewCanvasInfo(self.UMG_Login_Register.Update)
  self.CanvasMap[LoginEnum.CanvasNames.ScanLoginPanel] = LoginUtils.NewCanvasInfo(self.UMG_Login_Register.Btn_ScanLogin)
  self.CanvasMap[LoginEnum.CanvasNames.DownloadPanel] = LoginUtils.NewCanvasInfo(self.UMG_Login_Register.Download)
  self.CanvasMap[LoginEnum.CanvasNames.CustomerServicePanel] = LoginUtils.NewCanvasInfo(self.UMG_Login_Register.Btn_CustomerService)
  self.CanvasMap[LoginEnum.CanvasNames.CustomerServicePanel_1] = LoginUtils.NewCanvasInfo(self.UMG_Login_Register.Btn_CustomerService_1)
  self.AuthType = {
    kAuthNone = 0,
    kAuthMSDKv3 = 32767,
    kAuthMSDKv5 = 4096,
    kAuthWeGame = 4101,
    kAuthMSDKPC = 4102,
    kAuthMSDKPCUID = 4105,
    kAuthMSDKV5UID = 4112,
    kAuthINTL = 4117
  }
  self.ChannelType = {
    kChannelNone = 0,
    kChannelTWChat = 1,
    kChannelTQChat = 2,
    kChannelWechat = 1,
    kChannelQQ = 2,
    kChannelGuest = 3,
    kChannelTwitter = 9,
    kChannelGarena = 10,
    kChannelLine = 14,
    kChannelApple = 15
  }
  self.Mask_ToLoading:SetVisibility(UE4.ESlateVisibility.Hidden)
  self:RegisterEvents()
  self.AnimationEventMap = {}
  if self.UMG_Login_Register.Btn_Repair_1 then
    self.UMG_Login_Register.Btn_Repair_1:SetVisibility(UE4.ESlateVisibility.Visible)
  end
  if self.UMG_Login_Register.Btn_CustomerService_1 then
    self.UMG_Login_Register.Btn_CustomerService_1:SetVisibility(UE4.ESlateVisibility.Visible)
  end
  if UE4.UNRCStatics.IsRunningOnWindows() then
    self.UMG_Login_Register.Btn_WriteOff:SetVisibility(UE4.ESlateVisibility.Collapsed)
  end
  if self.UMG_Login_Register.Download then
    self.UMG_Login_Register.Download:SetVisibility(UE4.ESlateVisibility.Collapsed)
  end
  if RocoEnv.PLATFORM_IOS then
    UE.UNRCDeviceInfoHelper.GetDeviceUAAsync({
      self,
      function(_, result, error)
        Log.Debug("result: ", result, ", and error", error)
        NRCModuleManager:DoCmd(OnlineModuleCmd.UpdateDeviceInfoAsync, "user_agent", not string.IsNilOrEmpty(result) and result or "")
      end
    })
  end
  if _G.AppMain:IsMobilePlatform() then
    self.UMG_Login_Register.Compliance:SetVisibility(UE4.ESlateVisibility.Hidden)
  end
end

function UMG_Login_New_C:OnForceEnableSelection()
  Log.Error("Try force enable selection")
  self.SelectServer:SetVisibility(UE4.ESlateVisibility.Visible)
  self.SelectGroup:SetVisibility(UE4.ESlateVisibility.Visible)
  if self.SelectCulture then
    self.SelectCulture:SetVisibility(UE4.ESlateVisibility.Visible)
  end
end

function UMG_Login_New_C:ShowUserNameAndServer(TurnOn)
  if TurnOn then
    if LoginUtils.Debug or self.data:GetCondition(LoginEnum.Conditions.EnableServerChoose) then
      self.SelectServer:SetVisibility(UE4.ESlateVisibility.Visible)
      self.SelectGroup:SetVisibility(UE4.ESlateVisibility.Visible)
      if self.SelectCulture then
        self.SelectCulture:SetVisibility(UE4.ESlateVisibility.Visible)
      end
      self.UsernameDisplay:SetVisibility(UE4.ESlateVisibility.Visible)
      self.InputTextName:SetVisibility(UE4.ESlateVisibility.Visible)
      self.TriggerInput:SetVisibility(UE4.ESlateVisibility.Visible)
      self:AddButtonListener(self.TriggerInput, self.StartEditName)
    end
  elseif not LoginUtils.Debug and not self.data:GetCondition(LoginEnum.Conditions.EnableServerChoose) and 0 == table.len(AppMain.launchParams) then
    self.SelectServer:SetVisibility(UE4.ESlateVisibility.Hidden)
    self.SelectGroup:SetVisibility(UE4.ESlateVisibility.Hidden)
    if self.SelectCulture then
      self.SelectCulture:SetVisibility(UE4.ESlateVisibility.Hidden)
    end
    self.UsernameDisplay:SetVisibility(UE4.ESlateVisibility.Collapsed)
    self.InputTextName:SetVisibility(UE4.ESlateVisibility.Collapsed)
    self:RemoveButtonListener(self.TriggerInput)
  end
end

function UMG_Login_New_C:StartCamera()
  self.WebCamera:SetDeviceId(self.WebCamera:GetFrontCameraId())
end

function UMG_Login_New_C:DoPlayAnimation(Name)
  self:TryPlayAnimationAndRegisterEvent(Name, LoginModuleEvent.UIAnimationDone)
end

function UMG_Login_New_C:RegisterEvents()
  self:RegisterEvent(self, LoginModuleEvent.ItemClick, self.OnServerItemClick)
  self:RegisterEvent(self, LoginModuleEvent.EnterGame, self.EnterGame)
  self:RegisterEvent(self, LoginModuleEvent.CultureClick, self.OnCultureItemClick)
  NRCEventCenter:RegisterEvent("UMG_Login_New_C", self, LoginModuleEvent.HideLoginPanels, self.HideLoginPanels)
  NRCEventCenter:RegisterEvent("UMG_Login_New_C", self, LoginModuleEvent.EnableSelection, self.EnableSelection)
  NRCEventCenter:RegisterEvent("UMG_Login_New_C", self, LoginModuleEvent.WhiteListBlocked, self.OnWhiteListBlocked)
  NRCEventCenter:RegisterEvent("UMG_Login_New_C", self, LoginModuleEvent.DisableSelection, self.DisableSelection)
  NRCEventCenter:RegisterEvent("UMG_Login_New_C", self, LoginModuleEvent.SetCharacterToMale, self.SetCharacterToMale)
  NRCEventCenter:RegisterEvent("UMG_Login_New_C", self, LoginModuleEvent.SetCharacterToFemale, self.SetCharacterToFemale)
  NRCEventCenter:RegisterEvent("UMG_Login_New_C", self, LoginModuleEvent.CheckRestartLogin, self.OnCheckRestartLogin)
  NRCEventCenter:RegisterEvent("UMG_Login_New_C", self, LoginModuleEvent.PendingLogin, self.OnEndLogin)
  NRCEventCenter:RegisterEvent("UMG_Login_New_C", self, LoginModuleEvent.AutoTestEnterText, self.AutoTestEnterText)
  NRCEventCenter:RegisterEvent("UMG_Login_New_C", self, _G.NRCGlobalEvent.ON_LOGIN, self.OnLogin)
  NRCEventCenter:RegisterEvent("UMG_Login_New_C", self, LoginModuleEvent.OnClickAccountSwitch, self.OnClickAccountSwitch)
  NRCEventCenter:RegisterEvent("UMG_Login_New_C", self, LoginModuleEvent.ForceEnableSelection, self.OnForceEnableSelection)
  NRCEventCenter:RegisterEvent("UMG_Login_New_C", self, LoginModuleEvent.OnServerNodeUpdated, self.OnServerNodeUpdated)
  NRCEventCenter:RegisterEvent("UMG_Login_New_C", self, LoginModuleEvent.OnClickAnnouncement, self.OnClickAnnouncement)
  NRCEventCenter:RegisterEvent("UMG_Login_New_C", self, LoginModuleEvent.OnClickExitGame, self.OnClickExitGame)
  NRCEventCenter:RegisterEvent("UMG_Login_New_C", self, LoginModuleEvent.BtnAutoGameClick, self.BtnAutoGameClick)
  NRCEventCenter:RegisterEvent("UMG_Login_New_C", self, LoginModuleEvent.ClearBtnSelection, self.OnClearAllBtnSelection)
  NRCEventCenter:RegisterEvent("UMG_Login_New_C", self, LoginModuleEvent.OnBtnDownloadClick, self.OnBtnDownloadClick)
  NRCEventCenter:RegisterEvent("UMG_Login_New_C", self, LoginModuleEvent.OnClickCustomerService, self.OnClickCustomerService)
end

function UMG_Login_New_C:UnRegisterEvents()
  self:UnRegisterEvent(self, LoginModuleEvent.ItemClick, self.OnServerItemClick)
  self:UnRegisterEvent(self, LoginModuleEvent.EnterGame, self.EnterGame)
  self:UnRegisterEvent(self, LoginModuleEvent.CultureClick, self.OnCultureItemClick)
  NRCEventCenter:UnRegisterEvent(self, LoginModuleEvent.HideLoginPanels, self.HideLoginPanels)
  NRCEventCenter:UnRegisterEvent(self, LoginModuleEvent.EnableSelection, self.EnableSelection)
  NRCEventCenter:UnRegisterEvent(self, LoginModuleEvent.DisableSelection, self.DisableSelection)
  NRCEventCenter:UnRegisterEvent(self, LoginModuleEvent.SetCharacterToMale, self.SetCharacterToMale)
  NRCEventCenter:UnRegisterEvent(self, LoginModuleEvent.SetCharacterToFemale, self.SetCharacterToFemale)
  NRCEventCenter:UnRegisterEvent(self, LoginModuleEvent.CheckRestartLogin, self.OnCheckRestartLogin)
  NRCEventCenter:UnRegisterEvent(self, LoginModuleEvent.PendingLogin, self.OnEndLogin)
  NRCEventCenter:UnRegisterEvent(self, LoginModuleEvent.EndLogin, self.OnEndLogin)
  NRCEventCenter:UnRegisterEvent(self, LoginModuleEvent.AutoTestEnterText, self.AutoTestEnterText)
  NRCEventCenter:UnRegisterEvent(self, _G.NRCGlobalEvent.ON_LOGIN, self.OnLogin)
  NRCEventCenter:UnRegisterEvent(self, LoginModuleEvent.OnClickAccountSwitch, self.OnClickAccountSwitch)
  NRCEventCenter:UnRegisterEvent(self, LoginModuleEvent.WhiteListBlocked, self.OnWhiteListBlocked)
  NRCEventCenter:UnRegisterEvent(self, LoginModuleEvent.ForceEnableSelection, self.OnForceEnableSelection)
  NRCEventCenter:UnRegisterEvent(self, LoginModuleEvent.OnServerNodeUpdated, self.OnServerNodeUpdated)
  NRCEventCenter:UnRegisterEvent(self, LoginModuleEvent.OnClickAnnouncement, self.OnClickAnnouncement)
  NRCEventCenter:UnRegisterEvent(self, LoginModuleEvent.OnClickExitGame, self.OnClickExitGame)
  NRCEventCenter:UnRegisterEvent(self, LoginModuleEvent.BtnAutoGameClick, self.BtnAutoGameClick)
  NRCEventCenter:UnRegisterEvent(self, LoginModuleEvent.ClearBtnSelection, self.OnClearAllBtnSelection)
  NRCEventCenter:UnRegisterEvent(self, LoginModuleEvent.OnBtnDownloadClick, self.OnBtnDownloadClick)
  NRCEventCenter:UnRegisterEvent(self, LoginModuleEvent.OnClickCustomerService, self.OnClickCustomerService)
end

function UMG_Login_New_C:OnBtnDownloadClick()
  Log.Debug("[UMG_Login_New_C:OnBtnDownloadClick]")
  self:SetIfShowResDownloadBtnRedDot(false)
  _G.NRCModuleManager:DoCmd(LoginModuleCmd.SetSelectTabIndex, 0)
  local bNeedToDownload = _G.PufferUpdateResTask:IsNeedDownloadBasePaksWithPatch()
  if bNeedToDownload then
    local Context = DialogContext()
    local NeedToDownloadBasePakList, SizeNeedToDownload, LargestSize = _G.PufferUpdateResTask:GetBasePakListWithPatchNeedToDownload()
    local GB = string.format("%.2f", SizeNeedToDownload / 1024 / 1024 / 1024)
    local Content
    if _G.NRCBackgroundDownloadMgr:IsEnableBackgroundDownload() then
      local AppendText = string.format([[
 
%s]], LuaText.Download_All_tips3)
      Content = string.format(LuaText.Download_All_tips2, AppendText, GB)
    else
      Content = string.format(LuaText.Download_All_tips2, "", GB)
    end
    Context:SetTitle(LuaText.updateuimodule_26):SetContent(Content):SetMode(DialogContext.Mode.OK_CANCEL):SetButtonText(LuaText.Download_All_button2, LuaText.Download_All_button1):SetCloseOnCancel(true):SetCallback(self, function(this, result)
      if result then
        NRCEventCenter:DispatchEvent(UpdateUIModuleEvent.ReportDownloadBtnClick, LoginEnum.DownloadReportType.BaseDownloadBtn)
        LoginUtils.SendEventToLoginFsm(LoginModuleEvent.CheckIfDownloadBaseResAfterLogin)
      else
        NRCEventCenter:DispatchEvent(UpdateUIModuleEvent.ReportDownloadBtnClick, LoginEnum.DownloadReportType.RefuseBaseDownloadBtn)
      end
    end)
    NRCModuleManager:DoCmd(TipsModuleCmd.Dialog_OpenDialog, Context)
  else
    Log.Error("UMG_Login_New_C:OnBtnDownloadClick: \228\184\141\229\186\148\232\175\165\230\152\190\231\164\186\228\184\139\232\189\189\230\140\137\233\146\174")
  end
end

function UMG_Login_New_C:OnClickCustomerService()
  Log.Debug("[UMG_Login_New_C:OnClickCustomerService]")
  _G.NRCAudioManager:PlaySound2DAuto(1064, "UMG_Login_New_C:OnClickCustomerService")
  self:DelaySeconds(0.1, function()
    _G.NRCSDKManager:CustomerService(1)
    _G.NRCModuleManager:DoCmd(LoginModuleCmd.SetSelectTabIndex, 0)
  end)
end

function UMG_Login_New_C:OnWhiteListBlocked()
  Log.Debug("UMG_Login_New_C:OnWhiteListBlocked")
  NRCModuleManager:DoCmd(OnlineModuleCmd.Logout)
  self.TryConnecting = false
  if RocoEnv.PLATFORM_WINDOWS and self.data and self.data:GetCondition(LoginEnum.Conditions.UseWeGame) then
    Log.Debug("ignore this event when using wegame, avoid redundant login")
    return
  end
  self:OnClickBack()
  if RocoEnv.PLATFORM_WINDOWS then
    LoginUtils.SendEventToLoginFsm(LoginModuleEvent.OnDisconnected)
  else
    LoginUtils.SendEventToLoginFsm(LoginModuleEvent.AccountSwitch)
  end
end

function UMG_Login_New_C:InitVariables()
  self.data = self.module:GetData("LoginData")
  self.bInSelectionSpinPhase = false
  self.UseTimerFlag = true
end

function UMG_Login_New_C:OnDisable()
end

function UMG_Login_New_C:OnDestruct()
  self:Log("UMG_LoginPanel_C:OnDestruct")
  self:UnRegisterEvents()
  if self.CandidateListScroll then
    self.CandidateListScroll:ReleaseForce()
  end
  if self.CandidateListScroll_Group then
    self.CandidateListScroll_Group:ReleaseForce()
  end
  table.clear(self.VideoMap)
  table.clear(self.AnimationMap)
  table.clear(self.CanvasMap)
end

function UMG_Login_New_C:OnActive()
  Log.Debug("UMG_Login_New active")
  local encodeStr = "https://qq.com"
  self.UMG_Login_Register:OnActive(LoginEnum.PanelType.Login)
  local AppMain = _G.App
  self.TxtAppVersion:SetText(AppMain:GetAppVersion())
  self.TxtResVersion:SetText(AppMain:GetResVersion())
  self.TxtBuild:SetText(AppMain:GetResRevision())
  self:AddButtonListener(self.SelectButton_Group, self.OpenGroupList)
  self:AddButtonListener(self.ButtonCloseSelect_Group, self.OpenGroupList)
  self:AddButtonListener(self.SelectButton, self.OpenSelectList)
  self:AddButtonListener(self.ButtonCloseSelect, self.OpenSelectList)
  self:AddButtonListener(self.UMG_Login_Register.UMG_Login_QQ.LoginButton, self.OnClickQQLogin)
  self:AddButtonListener(self.UMG_Login_Register.UMG_Login_VX.LoginButton, self.OnClickVXLogin)
  self:AddButtonListener(self.UMG_Login_Register.AgeHint, self.OnClickAgeHint)
  self:AddButtonListener(self.ButtonLogin, self.OnClickLogin)
  self:AddButtonListener(self.ButtonEnter, self.OnClickEnter)
  self:AddButtonListener(self.TriggerInput, self.StartEditName)
  self:AddButtonListener(self.ButtonBack, self.OnClickBack)
  self:AddDelegateListener(self.InputTextName.OnTextCommitted, self.OnTextChanged)
  if self.SelectButton_1 then
    self:AddButtonListener(self.SelectButton_1, self.OpenCultureList)
  end
  if self.ButtonCloseSelect_1 then
    self:AddButtonListener(self.ButtonCloseSelect_1, self.OpenCultureList)
  end
  self:InitVariables()
  self.data:BuildOpenID()
  self:RefreshServerList()
  self:SetupInputBox()
  self:OnServerSelected(self.data.selectedServer)
  self:InitView()
  self:PlayAnimation(self.LogoOut, 0, 1, UE4.EUMGSequencePlayMode.Reverse, 1.0, false)
  local version = _G.DataConfigManager:GetWaterMarkLocalizationConf("permanent_watermark_lowerleft")
  if version and version.msg then
    self.Text:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
    self.Text:SetText(version.msg)
  else
    self.Text:SetVisibility(UE4.ESlateVisibility.Collapsed)
  end
  if self.SelectCulture then
    self.SelectCulture:SetVisibility(UE4.ESlateVisibility.Hidden)
  end
  if UE4.UNRCStatics.IsAutoTesting() then
    self:Log("AutoTesting... auto login")
    self:AutoLogin()
  end
  self:ShowDeepLogNoticeIfOpen()
end

function UMG_Login_New_C:ShowDeepLogNoticeIfOpen()
  if self.bHasShownDeepLogNotice then
    return
  end
  local Tag = GameSetting:GetUploadLogTag()
  if "High" == Tag then
    self.bHasShownDeepLogNotice = true
    local Context = DialogContext()
    Context:SetTitle(LuaText.umg_login_new_2):SetContent(LuaText.deep_log_description):SetMode(DialogContext.Mode.OK_CANCEL):SetButtonText(LuaText.deep_log_close, LuaText.deep_log_open):SetCallback(self, function(this, bOK)
      if bOK then
        GameSetting:SetLogLevel(0)
        GameSetting:SyncUploadLogTag("Low")
        GameSetting:Save()
      end
    end)
    NRCModuleManager:DoCmd(TipsModuleCmd.Dialog_OpenDialog, Context)
  end
end

function UMG_Login_New_C:OnClickAgeHint()
  local Context = DialogContext()
  Context:SetTitle(LuaText.umg_login_new_1):SetContent(LoginUtils.GetAgeHintText()):SetMode(DialogContext.Mode.NotBtn):SetCloseOnOK(true):SetCloseOnCancel(true):SetButtonText(LuaText.YES, LuaText.NO)
  NRCModuleManager:DoCmd(TipsModuleCmd.Dialog_OpenLongDialog, Context)
end

function UMG_Login_New_C:OnClickAccountSwitch()
  if UE4.UNRCStatics.IsRunningOnWindows() then
    local Ctx = DialogContext()
    Ctx:SetTitle(LuaText.switch_account_tips_pc):SetMode(DialogContext.Mode.OK_CANCEL):SetCloseOnCancel(true):SetButtonText(LuaText.YES, LuaText.No):SetCallback(self, self.OnAccountSwitchDialogCallback)
    _G.NRCModuleManager:DoCmd(TipsModuleCmd.Dialog_OpenDialog, Ctx)
  else
    self:ShowCanvas(LoginEnum.CanvasNames.NRCLoginPanel, false)
    NRCModuleManager:DoCmd(OnlineModuleCmd.Logout)
    self:OnClickBack()
    LoginUtils.SendEventToLoginFsm(LoginModuleEvent.AccountSwitch)
    if _G.RocoEnv.PLATFORM_ANDROID then
      CommonUtils.SendClientEventToCGSDK("{\"name\":\"game-event-progress\", \"content\":{\"type\":\"logout\"}}")
    end
  end
end

function UMG_Login_New_C:OnAccountSwitchDialogCallback(bOK)
  if bOK then
    NRCModuleManager:DoCmd(OnlineModuleCmd.Logout)
    LoginUtils.SendEventToLoginFsm(LoginModuleEvent.AccountSwitchOnPC)
    self.ConfirmQuitGame()
  end
end

function UMG_Login_New_C:OnClickExitGame()
  if RocoEnv.PLATFORM_WINDOWS then
    local Context = DialogContext()
    Context:SetTitle(LuaText.TIPS):SetMode(LuaText.Mode.OK_CANCEL):SetContent(LuaText.setting_quit_the_client):SetCallback(self, self.OnExitGameDialogCallback):SetCloseOnCancel(true):SetCloseOnOK(true):SetButtonText(LuaText.umg_systemsettingmain_5, LuaText.umg_systemsettingmain_6)
    _G.NRCModuleManager:DoCmd(TipsModuleCmd.Dialog_OpenDialog, Context)
  end
end

function UMG_Login_New_C:OnExitGameDialogCallback(bOK)
  if bOK then
    self.ConfirmQuitGame()
  else
    _G.NRCModuleManager:DoCmd(LoginModuleCmd.SetSelectTabIndex, 0)
  end
end

function UMG_Login_New_C:OnClickAnnouncement()
  NRCProfilerLog:NRCClickBtn(true, "AnnouncementPanel")
  _G.NRCModuleManager:DoCmd(_G.LoginModuleCmd.LoadLoginNoticeData, self, self.OnLoadLoginNoticeDataCallback)
end

function UMG_Login_New_C:OnLoadLoginNoticeDataCallback(noticeList)
  self:Log("OnLoadLoginNoticeDataCallback")
  if UE4.UNoticeStatics.IsLoginNotice() then
    _G.NRCModuleManager:DoCmd(_G.LoginModuleCmd.OpenAnnouncementPanel, noticeList)
  end
end

function UMG_Login_New_C:OnClickRepair()
  _G.NRCAudioManager:PlaySound2DAuto(41401005, "UMG_Login_New_C:OnClickRepair")
  _G.NRCModuleManager:DoCmd(UpdateUIModuleCmd.OpenRepairToolsPanel)
end

function UMG_Login_New_C:BtnAutoGameClick()
  local Context = DialogContext()
  local ContentText = _G.DataConfigManager:GetLocalizationConf("setting_quit_the_client").msg
  Context:SetTitle(LuaText.umg_login_new_2):SetContent(ContentText):SetMode(DialogContext.Mode.OK_CANCEL):SetCallback(self, self.OnAutoGameCallBack):SetCloseOnCancel(true):SetCloseOnOK(true):SetButtonText(LuaText.umg_login_new_3, LuaText.umg_login_new_4)
  _G.NRCModuleManager:DoCmd(TipsModuleCmd.Dialog_OpenDialog, Context)
end

function UMG_Login_New_C:OnAutoGameCallBack(bOK)
  if bOK then
    if _G.RocoEnv.PLATFORM_ANDROID then
      CommonUtils.SendClientEventToCGSDK("{\"name\":\"game-event-progress\", \"content\":{\"type\":\"exitgame\"}}")
      self:DelaySeconds(0.5, function()
        self:ConfirmQuitGame()
      end)
    else
      self:ConfirmQuitGame()
    end
  else
    _G.NRCModuleManager:DoCmd(LoginModuleCmd.SetSelectTabIndex, 0)
  end
end

function UMG_Login_New_C:ConfirmQuitGame()
  UE4.UNRCStatics.QuitGame()
end

function UMG_Login_New_C:OnClickQQLogin()
  NRCProfilerLog:NRCClickBtn(true, "PrivacyTips")
  LoginUtils.SendEventToLoginFsm(LoginModuleEvent.QQLoginChosen)
  self.data:SetCondition(LoginEnum.Conditions.UseQrCodeLogin, false)
end

function UMG_Login_New_C:OnClickVXLogin()
  NRCProfilerLog:NRCClickBtn(true, "PrivacyTips")
  LoginUtils.SendEventToLoginFsm(LoginModuleEvent.VXLoginChosen)
  self.data:SetCondition(LoginEnum.Conditions.UseQrCodeLogin, false)
end

function UMG_Login_New_C:SetCharacterToMale()
end

function UMG_Login_New_C:WrappedCheckValid()
  if nil == self then
    return false
  else
    return UE4.UObject.IsValid(self)
  end
end

function UMG_Login_New_C:SetCharacterToFemale(caller, callback)
end

function UMG_Login_New_C:OverwriteWorldVisibility(bSetAllInvisible)
  UE4Helper.SetEnableWorldRendering(not bSetAllInvisible)
  local AllActors = UE4.UGameplayStatics.GetAllActorsOfClass(UE4Helper.GetCurrentWorld(), UE4.AActor):ToTable()
  for i = 1, #AllActors do
    local curActor = AllActors[i]
    curActor:SetActorTickEnabled(not bSetAllInvisible)
  end
end

function UMG_Login_New_C:AutoLogin()
  local ServerList = self.data:GetServerList()
  for i, v in ipairs(ServerList) do
    if v.ip == "cndev.nrc.qq.com" and v.port == 8098 then
      self.data:SetServer(v)
    end
  end
  self:OnClickLogin()
end

function UMG_Login_New_C:OnDeactive(...)
end

local function ClearItemSelected(ListScroll, TargetIndex)
  local items = ListScroll:GetItems()
  local count = ListScroll:GetItemCount()
  for i = 1, count do
    local item = items[i]
    if item and TargetIndex ~= item.index and item.ClearItemSelected then
      item:ClearItemSelected()
    end
  end
end

function UMG_Login_New_C:ShowLoginButton()
  if self.data:HasServer() then
    self.LoginBtnFX:SetVisibility(UE4.ESlateVisibility.Visible)
    self.ButtonLogin:SetVisibility(UE4.ESlateVisibility.Visible)
  else
    self.ButtonLogin:SetVisibility(UE4.ESlateVisibility.Hidden)
    self.LoginBtnFX:SetVisibility(UE4.ESlateVisibility.Hidden)
  end
  self.EnterCanvas:SetVisibility(UE4.ESlateVisibility.Hidden)
  self.TriggerInput:SetVisibility(UE4.ESlateVisibility.Visible)
end

function UMG_Login_New_C:OnGroupSelected(item)
  ClearItemSelected(self.CandidateListScroll_Group, _G.GameSetting.GroupIndex)
  self:PlayAnimation(self.Login2_In, 0, 1, UE4.EUMGSequencePlayMode.Forward, 1.0, false)
  local GroupName = item.key
  Log.Debug("[UMG_Login_New_C:OnGroupSelected] GroupName: ", GroupName)
  self.Display_Group:SetText(GroupName)
  local ServerList = self.data:GetServerList(GroupName)
  _G.GameSetting.ServerIndex = 1
  local DefaultServer = ServerList[1]
  self.data:SetServer(DefaultServer)
  self.Display:SetText(DefaultServer.key)
  self.CandidateListScroll:InitList(ServerList)
  self:CloseGroupList()
end

function UMG_Login_New_C:OpenGroupList()
  NRCModuleManager:DoCmd(OnlineModuleCmd.Logout)
  self.EnterCanvas:SetVisibility(UE4.ESlateVisibility.Hidden)
  self.TriggerInput:SetVisibility(UE4.ESlateVisibility.Hidden)
  self.InputTextName:SetVisibility(UE4.ESlateVisibility.Hidden)
  if self.CandidateListScroll_Group:GetVisibility() == UE4.ESlateVisibility.Visible then
    self:CloseGroupList()
    UE4.UNRCAudioManager.Get():PlaySound2DAuto(1089, "UMG_Login_New_C:OnTextChanged")
    self:PlayAnimation(self.Login2_In, 0, 1, UE4.EUMGSequencePlayMode.Forward, 1.0, false)
  else
    UE4.UNRCAudioManager.Get():PlaySound2DAuto(1086, "UMG_Login_New_C:OpenSelectList")
    self.SelectButton_Group:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
    self.ButtonCloseSelect_Group:SetVisibility(UE4.ESlateVisibility.Visible)
    self:PlayAnimation(self.Login2_Out, 0, 1, UE4.EUMGSequencePlayMode.Forward, 1.0, false)
    self:PlayAnimation(self.ArrowDownToUp_Group, 0, 1, UE4.EUMGSequencePlayMode.Forward, 1.0, false)
    self.SelectButton_Group:SetVisibility(UE4.ESlateVisibility.Visible)
    self.ButtonLogin:SetVisibility(UE4.ESlateVisibility.Hidden)
    self.LoginBtnFX:SetVisibility(UE4.ESlateVisibility.Hidden)
    self:ToggleGroupList(true)
    self.DownArrow_Group:SetVisibility(UE4.ESlateVisibility.Visible)
    self:PlayAnimation(self.SelectServerIn, 0, 1, UE4.EUMGSequencePlayMode.Forward, 1.0, false)
    if _G.GameSetting.GroupIndex and _G.GameSetting.GroupIndex > self.CandidateListScroll_Group:GetItemCount() // 2 then
      self.CandidateListScroll_Group:ScrollToEnd()
    else
      self.CandidateListScroll_Group:ScrollToStart()
    end
  end
end

function UMG_Login_New_C:CloseGroupList()
  self:PlayAnimation(self.ArrowDownToUp_Group, 0, 1, UE4.EUMGSequencePlayMode.Reverse, 1.0, false)
  self.SelectButton_Group:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
  self:ToggleGroupList(false)
  self.SelectButton_Group:SetVisibility(UE4.ESlateVisibility.Visible)
  self:ShowLoginButton()
  self.ButtonCloseSelect_Group:SetVisibility(UE4.ESlateVisibility.Hidden)
end

function UMG_Login_New_C:OnServerSelected(item)
  if not item or item.isGroup then
    return
  end
  ClearItemSelected(self.CandidateListScroll, _G.GameSetting.ServerIndex)
  self.data:SetServer(item)
  self:Log("UMG_Login_New_C:OnServerSelected:", item.key, item.ip, item.port)
  self:CloseSelectList()
  self:PlayAnimation(self.Login2_In, 0, 1, UE4.EUMGSequencePlayMode.Forward, 1.0, false)
  self.Display:SetText(item.key)
end

function UMG_Login_New_C:CloseSelectList()
  self:PlayAnimation(self.SelectServerOut, 0, 1, UE4.EUMGSequencePlayMode.Forward, 1.0, false)
  self:PlayAnimation(self.ArrowDownToUp, 0, 1, UE4.EUMGSequencePlayMode.Reverse, 1.0, false)
  self.SelectButton:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
  self:ToggleCandidateList(false)
  self.SelectButton:SetVisibility(UE4.ESlateVisibility.Visible)
  self:ShowLoginButton()
  self.ButtonCloseSelect:SetVisibility(UE4.ESlateVisibility.Hidden)
end

function UMG_Login_New_C:OpenSelectList()
  self:Log("OpenSelectList:", type(self.CandidateListScroll))
  NRCModuleManager:DoCmd(OnlineModuleCmd.Logout)
  self.EnterCanvas:SetVisibility(UE4.ESlateVisibility.Hidden)
  self.TriggerInput:SetVisibility(UE4.ESlateVisibility.Hidden)
  self.InputTextName:SetVisibility(UE4.ESlateVisibility.Hidden)
  if self.CandidateListScroll:GetVisibility() == UE4.ESlateVisibility.Visible then
    self:CloseSelectList()
    UE4.UNRCAudioManager.Get():PlaySound2DAuto(1089, "UMG_Login_New_C:OnTextChanged")
    self:PlayAnimation(self.Login2_In, 0, 1, UE4.EUMGSequencePlayMode.Forward, 1.0, false)
  else
    UE4.UNRCAudioManager.Get():PlaySound2DAuto(1086, "UMG_Login_New_C:OpenSelectList")
    self.SelectButton:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
    self.ButtonCloseSelect:SetVisibility(UE4.ESlateVisibility.Visible)
    self:PlayAnimation(self.Login2_Out, 0, 1, UE4.EUMGSequencePlayMode.Forward, 1.0, false)
    self:PlayAnimation(self.ArrowDownToUp, 0, 1, UE4.EUMGSequencePlayMode.Forward, 1.0, false)
    self.SelectButton:SetVisibility(UE4.ESlateVisibility.Visible)
    self.ButtonLogin:SetVisibility(UE4.ESlateVisibility.Hidden)
    self.LoginBtnFX:SetVisibility(UE4.ESlateVisibility.Hidden)
    self:ToggleCandidateList(true)
    self.DownArrow:SetVisibility(UE4.ESlateVisibility.Visible)
    self:PlayAnimation(self.SelectServerIn, 0, 1, UE4.EUMGSequencePlayMode.Forward, 1.0, false)
    if _G.GameSetting.ServerIndex > self.CandidateListScroll:GetItemCount() // 2 then
      self:Log("Bottom Side!")
      self.CandidateListScroll:ScrollToEnd()
    else
      self:Log("Top Side!")
      self.CandidateListScroll:ScrollToStart()
    end
  end
end

function UMG_Login_New_C:CloseCultureList()
  self:PlayAnimation(self.SelectCultureOut, 0, 1, UE4.EUMGSequencePlayMode.Forward, 1.0, false)
  self:PlayAnimation(self.CultureArrowDownToUp, 0, 1, UE4.EUMGSequencePlayMode.Reverse, 1.0, false)
  self.SelectButton_1:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
  self:ToggleCultureList(false)
  self.SelectButton_1:SetVisibility(UE4.ESlateVisibility.Visible)
  if self.ButtonCloseSelect_1 then
    self.ButtonCloseSelect_1:SetVisibility(UE4.ESlateVisibility.Hidden)
  end
end

function UMG_Login_New_C:OpenCultureList()
  self:Log("OpenCultureList:", type(self.CandidateListScroll_1))
  if self.CandidateListScroll_1:GetVisibility() == UE4.ESlateVisibility.Visible then
    self:CloseCultureList()
    return
  else
    self.SelectButton_1:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
    self.ButtonCloseSelect_1:SetVisibility(UE4.ESlateVisibility.Visible)
    self:PlayAnimation(self.CultureArrowDownToUp, 0, 1, UE4.EUMGSequencePlayMode.Forward, 1.0, false)
  end
  self:ToggleCultureList(true)
  self.DownArrow_1:SetVisibility(UE4.ESlateVisibility.Visible)
  self:PlayAnimation(self.SelectCultureIn, 0, 1, UE4.EUMGSequencePlayMode.Forward, 1.0, false)
end

function UMG_Login_New_C:ToggleGroupList(visible)
  self:Log("ToggleGroupList:", visible)
  if visible then
    self.CandidateListScroll_Group:SetVisibility(UE4.ESlateVisibility.Visible)
    if self.FrameBG_Group then
      self.FrameBG_Group:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
    end
  else
    self.CandidateListScroll_Group:SetVisibility(UE4.ESlateVisibility.Hidden)
    if self.FrameBG_Group then
      self.FrameBG_Group:SetVisibility(UE4.ESlateVisibility.Hidden)
    end
  end
end

function UMG_Login_New_C:ToggleCandidateList(visible)
  self:Log("ToggleCandidateList:", visible)
  if visible then
    self.CandidateListScroll:SetVisibility(UE4.ESlateVisibility.Visible)
    if self.FrameBG then
      self.FrameBG:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
    end
  else
    self.CandidateListScroll:SetVisibility(UE4.ESlateVisibility.Collapsed)
    if self.FrameBG then
      self.FrameBG:SetVisibility(UE4.ESlateVisibility.Collapsed)
    end
  end
end

function UMG_Login_New_C:ToggleCultureList(visible)
  self:Log("ToggleCultureList:", visible)
  if visible then
    self.CandidateListScroll_1:SetVisibility(UE4.ESlateVisibility.Visible)
    if self.FrameBG_1 then
      self.FrameBG_1:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
    end
  else
    self.CandidateListScroll_1:SetVisibility(UE4.ESlateVisibility.Collapsed)
    if self.FrameBG_1 then
      self.FrameBG_1:SetVisibility(UE4.ESlateVisibility.Collapsed)
    end
  end
end

function UMG_Login_New_C:RefreshServerList()
  self:SetupServerList()
  self:InitServerList()
end

function UMG_Login_New_C:SetupServerList()
  local CurrentServer = self.data:GetServer()
  if not CurrentServer then
    Log.Error("\230\156\141\229\138\161\229\153\168\229\136\151\232\161\168\229\136\157\229\167\139\229\140\150\229\164\177\232\180\165\239\188\140\232\175\183\230\139\191\231\157\128\232\191\153\228\184\170\230\138\165\233\148\153\230\137\190\231\174\161\231\153\187\229\189\149\231\154\132\229\188\128\229\143\145")
  end
  self:ToggleGroupList(false)
  self:ToggleCandidateList(false)
  local GroupName = CurrentServer.group
  local GroupList = self.data:GetGroupList()
  self.CandidateListScroll_Group:InitList(GroupList)
  local ServerList = self.data:GetServerList(GroupName)
  self.CandidateListScroll:InitList(ServerList)
  Log.DumpSingleLine(CurrentServer, 3, "CurrentServer")
end

function UMG_Login_New_C:SetupCultureList()
  self.ButtonCloseSelect_1:SetVisibility(UE4.ESlateVisibility.Hidden)
  local localizedCultures = UE4.UKismetInternationalizationLibrary.GetLocalizedCultures()
  local dataList = {}
  for i = 1, localizedCultures:Num() do
    local k = localizedCultures:Get(i)
    local data = {culture = k, index = i}
    table.insert(dataList, data)
  end
  self.CandidateListScroll_1:InitList(dataList)
  self:ToggleCultureList(false)
  local curCulture = UE4.UNRCStatics.GetCurrentCulture()
  local displayName = UE4.UKismetInternationalizationLibrary.GetCultureDisplayName(curCulture, false)
  self.Display_1:SetText(displayName)
end

local function GetItemIndexByKey(itemList, key)
  for i, v in ipairs(itemList) do
    if v.key == key then
      return i - 1
    end
  end
  return -1
end

function UMG_Login_New_C:InitServerList()
  local SelectedServer = self.data:GetServer()
  self:Log("[UMG_Login_New_C:InitServerList] SelectedServer ServerName:", SelectedServer.key)
  if SelectedServer then
    local GroupName = SelectedServer.group
    local GroupList = self.data:GetGroupList()
    local GroupIndex = GetItemIndexByKey(GroupList, GroupName)
    if -1 ~= GroupIndex then
      self.CandidateListScroll_Group:SelectItemByIndex(GroupIndex)
    end
    local ServerList = self.data:GetServerList(GroupName)
    local ServerIndex = GetItemIndexByKey(ServerList, SelectedServer.key)
    if -1 ~= ServerIndex then
      self.CandidateListScroll:SelectItemByIndex(ServerIndex)
    end
  else
    self:Warning("[UMG_Login_New_C:InitServerList] SelectedServer not found")
  end
end

function UMG_Login_New_C:OnServerItemClick(itemData)
  self:Log("OnItemClick:", itemData)
  UE4.UNRCAudioManager.Get():PlaySound2DAuto(1090, "UMG_Login_New_C:OnServerItemClick")
  if itemData.isGroup then
    self:OnGroupSelected(itemData)
  else
    self:OnServerSelected(itemData)
  end
end

function UMG_Login_New_C:OnCultureItemClick(itemData)
  local culture = UE4.UNRCStatics.GetCurrentCulture()
  self:Log("OnCultureClick:", itemData.culture, itemData.index, " current culture ", culture)
  local items = self.CandidateListScroll_1:GetItems()
  local num = self.CandidateListScroll_1:GetItemCount()
  for i = 1, num do
    if items[i] and items[i].data.culture ~= itemData.culture and items[i].ClearItemSelected then
      items[i]:ClearItemSelected()
    end
  end
  self:CloseCultureList()
  local displayName = UE4.UKismetInternationalizationLibrary.GetCultureDisplayName(itemData.culture, false)
  self.Display_1:SetText(displayName)
  local newCulture = itemData.culture
  _G.NRCModuleManager:DoCmd(LoginModuleCmd.ShowPanel, LoginEnum.PanelNames.NRCLoginPanel, false, {}, function()
    UE4.UNRCStatics.ChangeCurrentCulture(newCulture)
    Log.Info("CurrentCulture after switch ", UE4.UNRCStatics.GetCurrentCulture())
    _G.NRCModuleManager:DoCmd(LoginModuleCmd.ShowPanel, LoginEnum.PanelNames.NRCLoginPanel, true, {}, function()
      NRCModuleManager:DoCmd(LoginModuleCmd.ShowCanvas, LoginEnum.CanvasNames.NRCLoginPanel, true, LoginModuleEvent.UIAnimationDone)
      NRCModuleManager:DoCmd(LoginModuleCmd.ShowCanvas, LoginEnum.CanvasNames.NRCEnterPanel, true, LoginModuleEvent.UIAnimationDone)
      NRCModuleManager:DoCmd(LoginModuleCmd.ShowCanvas, LoginEnum.CanvasNames.AccountPanel, true, LoginModuleEvent.UIAnimationDone)
      NRCModuleManager:DoCmd(LoginModuleCmd.ShowCanvas, LoginEnum.CanvasNames.RepairToolsPanel, true, LoginModuleEvent.UIAnimationDone)
      _G.DataConfigManager:ChangeLanguage(string.gsub(newCulture, "-", "_"))
      local curCulture = UE4.UNRCStatics.GetCurrentCulture()
      if "zh-Hans-CN" == curCulture then
        _G.NRCAudioManager:ChangeLanguage("Chinese")
      elseif "en" == curCulture then
        _G.NRCAudioManager:ChangeLanguage("English")
      end
    end)
  end)
end

function UMG_Login_New_C:OnClickEnter()
  self:Log("UMG_LoginPanel_C:OnClickEnter")
  _G.NRCAutoDownloadManager:SetSpeedLimitMode()
  _G.NRCAutoDownloadManager:StartDownloadBasePaks()
  self.ButtonEnter:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
  NRCModuleManager:DoCmd(UpdateUIModuleCmd.StopVideoListMode)
  local _PlayerBriefInfo
  if _G.DataModelMgr.PlayerDataModel.playerInfo then
    _PlayerBriefInfo = _G.DataModelMgr.PlayerDataModel.playerInfo.brief_info
  end
  if _PlayerBriefInfo and _PlayerBriefInfo.sex ~= ProtoEnum.ESexValue.SEX_NOT_SEL and _PlayerBriefInfo.sex ~= ProtoEnum.ESexValue.SEX_NOT_SHOW then
    self:HideEnterButton()
    self.ButtonEnter:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
    _G.NRCAudioManager:SetStateByName("Login_Game", "Start_Game", "UMG_Login_New")
    self:DelaySeconds(0.6, function()
      self.ButtonEnter:SetVisibility(UE4.ESlateVisibility.Visible)
      LoginUtils.SendEventToLoginFsm(LoginModuleEvent.PlayerExist)
    end)
  else
    self:DelaySeconds(0.6, function()
      LoginUtils.SendEventToLoginFsm(LoginModuleEvent.PlayerNotExist)
    end)
  end
  self.Active = false
end

function UMG_Login_New_C:EnterGame()
  self:PlayAnimation(self.Transitions, 0, 1, UE4.EUMGSequencePlayMode.Forward, 1.0, false)
end

function UMG_Login_New_C:OnEndLogin()
  self.PendingEnd = true
end

function UMG_Login_New_C:OnConnected(errorCode)
  Log.Warning("UMG_Login_New OnConnected:", errorCode)
  self.TryConnecting = false
  if LoadingUIModuleCmd then
    NRCModuleManager:DoCmd(LoadingUIModuleCmd.CloseLoadingUI, 0)
  end
  if 0 ~= errorCode then
    self:BackToMain()
  end
end

function UMG_Login_New_C:OnDisconnect(errorCode)
  self:BackToMain()
end

function UMG_Login_New_C:OnStateChanged(state, errorCode)
  if not UE4.UNRCStatics.IsEditor() then
    self:BackToMain()
  end
end

function UMG_Login_New_C:OnLogin()
  if self.PendingEnd == true then
    return
  end
  if not self.TryConnecting then
    return
  end
  self.TryConnecting = false
  Log.PrintScreenMsg("UMG_Login_New OnLogin:")
  if self.bBlockLoginPanel then
    NRCModuleManager:DoCmd(OnlineModuleCmd.Logout)
    return
  end
  if LoginUtils.GetPropertyHolder() then
    LoginUtils.GetPropertyHolder().bIsMale = nil
  end
  self.LoginCanvas:SetVisibility(UE4.ESlateVisibility.Hidden)
  if self.data:GetEnterWorldWithoutDownloadRes() then
    self.data:SetEnterWorldWithoutDownloadRes(false)
    self:OnClickEnter()
  else
    local bDownloadBaseResAfterLogin = UE4.UNRCStatics.GetBoolFromGGameIni("/Script/NRC.PufferSettings", "DownloadBaseResAfterLogin")
    if RocoEnv.PLATFORM_WINDOWS then
      bDownloadBaseResAfterLogin = false
    end
    if bDownloadBaseResAfterLogin then
      LoginUtils.SendEventToLoginFsm(LoginModuleEvent.CheckIfDownloadBaseResAfterLogin)
    else
      self:OnClickEnter()
    end
  end
end

function UMG_Login_New_C:OnClickLogin()
  _G.GEMPostManager:GEMPostStepEvent("ClickLoginButton")
  UE4.UNRCAudioManager.Get():PlaySound2DAuto(1091, "UMG_Login_New_C:OnClickLogin")
  if string.SubStringGetTotalIndex(self:GetUsername()) > 30 then
    _G.NRCModeManager:DoCmd(TipsModuleCmd.TopHud_ShowTips, LuaText.umg_login_new_5, 0)
    self:StartEditName()
  else
    if self.TryConnecting then
      NRCModuleManager:DoCmd(OnlineModuleCmd.Logout)
    end
    if not self.data.selectedServer then
      self.data:SetDefaultServerChoiceIfPossible()
      return
    end
    if self.data.selectedServer.flag == LoginEnum.SvrTreeNodeFlag.Unavailable and not _G.AppMain:HasLaunchParams() then
      NRCModuleManager:DoCmd(LoginModuleCmd.RefreshServerNode, self.data.selectedServer.id)
      return
    end
    self:ShowCanvas(LoginEnum.CanvasNames.NRCBackPanel, false)
    self:ShowCanvas(LoginEnum.CanvasNames.NRCLoginPanel, false)
    self:ShowCanvas(LoginEnum.CanvasNames.AccountPanel, false)
    if self.UMG_Login_Register.AgeHint then
      self.UMG_Login_Register.AgeHint:SetVisibility(UE4.ESlateVisibility.Hidden)
    end
    local AuthType = self.AuthType.kAuthNone
    local ChannelType = self.ChannelType.kChannelNone
    if not self.data:GetCondition(LoginEnum.Conditions.SkipMSDK) then
      local Channel = self.data:GetCondition(LoginEnum.Conditions.LoginChannel)
      if Channel == LoginEnum.ChannelNames.QQ then
        AuthType = self.AuthType.kAuthMSDKv5
        ChannelType = self.ChannelType.kChannelQQ
      elseif Channel == LoginEnum.ChannelNames.WeChat then
        AuthType = self.AuthType.kAuthMSDKv5
        ChannelType = self.ChannelType.kChannelWechat
      end
    end
    local SelectedServer = self.data.selectedServer
    if not SelectedServer.encryptMethod and not SelectedServer.keyMakingMethod then
      AuthType = self.AuthType.kAuthNone
      ChannelType = self.ChannelType.kChannelNone
    elseif RocoEnv.PLATFORM_WINDOWS then
      AuthType = self.AuthType.kAuthMSDKv5
    end
    Log.PrintScreenMsg("Logining %d %s %s %s %s %s %s %s", self.data.selectedServer.id, self.data.selectedServer.key, AppMain.launchParams.servers, self.data.selectedServer.encryptMethod, self.data.selectedServer.keyMakingMethod, AuthType, ChannelType, self.data:GetToken())
    self.TryConnecting = true
    Log.Info("UMG_Login_New_C:OnClickLogin SetUserAccountInfo OpenID ", self.data:GetOpenID(), " Token ", self.data:GetToken(), " channel ", self.data:GetChannel(), " regChannelDis ", self.data:GetRegChannelDis(), " cli_startup_channel ", self.data:GetCliStartUpChannel())
    if RocoEnv.PLATFORM_WINDOWS then
      NRCModuleManager:DoCmd(OnlineModuleCmd.SetPackageChannel, self.data:GetPackageChannel())
    end
    NRCModuleManager:DoCmd(OnlineModuleCmd.SetUserAccountInfo, self.data:GetOpenID(), self.data:GetToken(), self.data:GetChannel(), self.data:GetRegChannelDis(), self.data:GetCliStartUpChannel(), self.data:GetExtraInfo())
    NRCModuleManager:DoCmd(OnlineModuleCmd.SetTpnsToken, self.data:GetTpnsToken())
    NRCModuleManager:DoCmd(OnlineModuleCmd.ConnectAndLogin, self.data.selectedServer.key, self.data.selectedServer.typeid, self.data.selectedServer.zoneid, self.data.selectedServer.ip, self.data.selectedServer.port, self.data:GetOpenID(), self.data.selectedServer.encryptMethod or 0, self.data.selectedServer.keyMakingMethod or 0, AuthType, ChannelType, self.data.selectedServer.clb)
  end
end

function UMG_Login_New_C:OnClickBack()
  self:ShowCanvas(LoginEnum.CanvasNames.NRCEnterPanel, false)
  self:BackToMain()
end

function UMG_Login_New_C:OnLogout()
  self.ButtonLogin:SetVisibility(UE4.ESlateVisibility.Visible)
  self.BackCanvas:SetVisibility(UE4.ESlateVisibility.Hidden)
  self.ButtonLogin:SetVisibility(UE4.ESlateVisibility.Visible)
  self.LoginCanvas:SetVisibility(UE4.ESlateVisibility.Visible)
end

function UMG_Login_New_C:StartEditName()
  self.currentName = self:GetUsername()
  self.InputTextName:SetVisibility(UE4.ESlateVisibility.Visible)
  self.TriggerInput:SetVisibility(UE4.ESlateVisibility.Hidden)
  self.InputTextName:SetFocus()
  UE4.UNRCAudioManager.Get():PlaySound2DAuto(1086, "UMG_Login_New_C:StartEditName")
end

function UMG_Login_New_C:OnTextChanged()
  self:Log("OnTextChanged")
  self.InputTextName:SetVisibility(UE4.ESlateVisibility.Hidden)
  self.TriggerInput:SetVisibility(UE4.ESlateVisibility.Visible)
  if self.InputTextName:GetText() == nil then
    self.InputTextName:SetText("")
  end
  self:SetUsername(self.InputTextName:GetText())
  self.data:SetOpenID(self.InputTextName:GetText())
  UE4.UNRCAudioManager.Get():PlaySound2DAuto(1089, "UMG_Login_New_C:OnTextChanged")
end

function UMG_Login_New_C:AutoTestEnterText(inText)
  if self.Active then
    self:SetUsername(inText)
  end
end

function UMG_Login_New_C:SetUsername(text)
  if "" == text then
    text = self.currentName
  end
  if nil ~= text then
    if string.SubStringGetTotalIndex(text) > 14 then
      self.InputTextName:SetJustification(UE4.ETextJustify.Left)
      self.UsernameDisplay:SetJustification(UE4.ETextJustify.Left)
    else
      self.InputTextName:SetJustification(UE4.ETextJustify.Center)
      self.UsernameDisplay:SetJustification(UE4.ETextJustify.Center)
    end
    self:Log("setusername:", text)
    self.InputTextName:SetText(text)
    self.UsernameDisplay:SetText(text)
  else
    Log.Error("UMG_Login_New_C text is nil")
  end
end

function UMG_Login_New_C:GetUsername()
  return self.InputTextName:GetText()
end

function UMG_Login_New_C:SetupInputBox()
  self.TriggerInput:SetVisibility(UE4.ESlateVisibility.Visible)
  self.InputTextName:SetVisibility(UE4.ESlateVisibility.Hidden)
  self.data:BuildOpenID()
  self:Log("\232\142\183\229\143\150\231\188\147\229\173\152\230\149\176\230\141\174:", self.data:GetOpenID())
  self:SetUsername(self.data:GetOpenID())
end

function UMG_Login_New_C:HideLoginPanels()
  self.LoginCanvas:SetVisibility(UE4.ESlateVisibility.Hidden)
  self.BackCanvas:SetVisibility(UE4.ESlateVisibility.Hidden)
end

function UMG_Login_New_C:EnableSelection()
  self.isConnected = true
end

function UMG_Login_New_C:DisableSelection()
end

function UMG_Login_New_C:OnCheckRestartLogin()
  NRCModuleManager:DoCmd(OnlineModuleCmd.Logout)
  self:InitView()
  self.LoginCanvas:SetVisibility(UE4.ESlateVisibility.Visible)
  self:PlayAnimation(self.EnterIn, 0, 1, UE4.EUMGSequencePlayMode.Forward, 1.0, false)
  self:PlayAnimation(self.LogoOut, 0, 1, UE4.EUMGSequencePlayMode.Reverse, 1.0, false)
end

function UMG_Login_New_C:InitView()
  self.PendingEnd = false
  self.Active = true
  self.InputTextName:SetVisibility(UE4.ESlateVisibility.Hidden)
  self.BackCanvas:SetVisibility(UE4.ESlateVisibility.Hidden)
  self.ButtonCloseSelect:SetVisibility(UE4.ESlateVisibility.Hidden)
  self.ButtonCloseSelect_Group:SetVisibility(UE4.ESlateVisibility.Hidden)
  self.ButtonLogin:SetVisibility(UE4.ESlateVisibility.Visible)
  if UE4.UNRCStatics.IsRunningOnIOS() then
    if UE4.ULoginStatics.IsVxInstalled() then
      self.UMG_Login_Register.UMG_Login_VX:SetVisibility(UE4.ESlateVisibility.Visible)
    else
      self.UMG_Login_Register.UMG_Login_VX:SetVisibility(UE4.ESlateVisibility.Collapsed)
    end
  elseif UE4.UNRCStatics.IsRunningOnWindows() then
  end
  UE.UNRCEnhancedInputHelper.UpdateCursor()
end

function UMG_Login_New_C:ShowPlatformLoginPanel(bTurnOn)
  self.bBlockLoginPanel = bTurnOn
  if not bTurnOn then
    self.UMG_Login_Register.Register:SetVisibility(UE4.ESlateVisibility.Hidden)
    _G.NRCModuleManager:DoCmd(_G.LoginModuleCmd.ShowPanel, "ScanLoginPanel", false)
    _G.NRCModuleManager:DoCmd(_G.LoginModuleCmd.ShowPanel, "CustomerServicePanel_1", false)
    _G.NRCEventCenter:DispatchEvent(LoginModuleEvent.UIAnimationDone)
  else
    self.UMG_Login_Register:PlayAnimation(self.UMG_Login_Register.Appear)
    self.UMG_Login_Register.Register:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
  end
end

function UMG_Login_New_C:ShowLoginTipsOnPC(bTurnOn)
end

function UMG_Login_New_C:TryPlayAnimationAndRegisterEvent(InAnimationName, InEvent, PanelOverride)
  if not InAnimationName then
    Log.Debug("UMG_Update_UI_C:TryPlayAnimationAndRegisterEvent:no animation")
    _G.NRCEventCenter:DispatchEvent(InEvent)
    return false
  end
  local Animation = self.AnimationMap[InAnimationName]
  if not Animation then
    Log.Error("No such animation")
    return false
  end
  if InEvent then
    self:RegisterAnimationToFsmEvent(InAnimationName, InEvent)
  end
  self:PlayAnimation(Animation)
  return true
end

function UMG_Login_New_C:RegisterAnimationToFsmEvent(AnimationName, InEvent)
  if self.AnimationEventMap then
    self.AnimationEventMap[AnimationName] = InEvent
  end
end

function UMG_Login_New_C:SendAnimationEventAndUnregister(InAnimationName)
  if self.AnimationEventMap ~= nil then
    local Event = self.AnimationEventMap[InAnimationName]
    self.AnimationEventMap[InAnimationName] = nil
    if Event then
      _G.NRCEventCenter:DispatchEvent(Event)
    else
      Log.Debug("UMG_Login_New_C: SendAnimationEvent: Animation Has no event")
    end
  else
    Log.Debug("UMG_Login_New_C: AnimationEventMap is not defined or SomeEvent not found")
  end
end

function UMG_Login_New_C:ShowCanvas(CanvasName, TurnOn, AnimationCompleteEvent)
  local CanvasInfo = self.CanvasMap[CanvasName]
  if not CanvasInfo then
    Log.Error("UMG_Login_New_C: Canvas name invalid", CanvasName)
    return
  end
  if TurnOn then
    _G.NRCModuleManager:DoCmd(LoginModuleCmd.SetSelectTabIndex, 0)
    CanvasInfo.Canvas:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
    self:TryPlayAnimationAndRegisterEvent(CanvasInfo.ShowAnimationName, AnimationCompleteEvent)
  else
    CanvasInfo.Canvas:SetVisibility(UE4.ESlateVisibility.Collapsed)
    self:TryPlayAnimationAndRegisterEvent(CanvasInfo.HideAnimationName, AnimationCompleteEvent)
  end
end

function UMG_Login_New_C:OnTick(deltaTime)
  if self.enableView and self.bDownloading then
    self:_internalSetProgress(self.TargetPercent / 100)
  end
end

function UMG_Login_New_C:_internalSetProgress(Percent)
  if Percent == self.TargetPercent / 100 and self.WaitForPercent then
    self.WaitForPercent = false
    _G.NRCEventCenter:DispatchEvent(LoginModuleEvent.ProgressHit)
  end
  self.LastPercent = Percent
  self.UMG_Login_Register.JinduProgressBar:SetPercent(Percent)
  self.UMG_Login_Register.Text_Schedule:SetText((self.ProgressHint or "") .. " " .. math.round(Percent * 100) .. "%")
end

function UMG_Login_New_C:SetProgress(Percent, Hint)
  self.WaitForPercent = true
  self.ProgressHint = Hint
  self.TargetPercent = 100 * Percent
end

function UMG_Login_New_C:SetIfShowResDownloadBtn(bShow)
  if bShow then
    self.UMG_Login_Register.Download:SetVisibility(UE4.ESlateVisibility.Visible)
  else
    self.UMG_Login_Register.Download:SetVisibility(UE4.ESlateVisibility.Collapsed)
  end
end

function UMG_Login_New_C:SetIfShowResDownloadBtnRedDot(bShow)
  if bShow then
    self.UMG_Login_Register:EnableDownloadBtnRedDot()
  else
    self.UMG_Login_Register:DisableDownloadBtnRedDot()
  end
end

function UMG_Login_New_C:SetIfShowNotificationBtn(bShow)
  if bShow then
    self.UMG_Login_Register:ShowNotificationBtn()
  else
    self.UMG_Login_Register:HideNotificationBtn()
  end
end

function UMG_Login_New_C:SetIsDownloading(isDownloading)
  self.bDownloading = isDownloading
end

function UMG_Login_New_C:OnAnimationFinished(Animation)
  local AnimationName = table.getKeyName(self.AnimationMap, Animation)
  self:SendAnimationEventAndUnregister(AnimationName)
end

function UMG_Login_New_C:BackToMain()
  Log.Debug("UMG_Login_New_C:BackToMain")
  NRCEventCenter:DispatchEvent(LoginModuleEvent.BackToMain)
  self.isConnected = true
  UE4.UNRCAudioManager.Get():PlaySound2DAuto(1092, "UMG_Login_New_C:PlayVideo")
  LoginUtils.SendEventToLoginFsm(LoginModuleEvent.OnDisconnected)
end

function UMG_Login_New_C:OnServerNodeUpdated()
  if self.data.selectedServer.flag == LoginEnum.SvrTreeNodeFlag.Unavailable then
    if not _G.AppMain:HasLaunchParams() then
      _G.NRCModeManager:DoCmd(TipsModuleCmd.TopHud_ShowTips, LuaText.maintenance_tips, 0)
      _G.GEMPostManager:GEMPostStepEvent("OpenAnnouncement")
    end
  else
    self:OnClickLogin()
  end
end

function UMG_Login_New_C:OnClearAllBtnSelection()
  local CurSelectIndex = _G.NRCModuleManager:DoCmd(LoginModuleCmd.GetSelectTabIndex)
  for i, btn in ipairs(self.BtnList) do
    btn:RemoveSelected(CurSelectIndex)
  end
end

return UMG_Login_New_C

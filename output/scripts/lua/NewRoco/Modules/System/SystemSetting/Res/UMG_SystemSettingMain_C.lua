local JsonUtils = require("Common.JsonUtils")
local _SleepConfigFilename = "NrcSleepConfig"
local _DLSSConfigFilename = "NrcDLSSConfig"
local SystemSettingModuleEvent = require("NewRoco.Modules.System.SystemSetting.SystemSettingModuleEvent")
local LoginEnum = require("NewRoco.Modes.LoginMode.LoginEnum")
local MainUIModuleEvent = require("NewRoco.Modules.System.MainUI.MainUIModuleEvent")
local SystemSettingEnum = require("NewRoco.Modules.System.SystemSetting.SystemSettingEnum")
local NRCSDKManagerEvent = require("Core.Service.SDKManager.NRCSDKManagerEvent")
local NRCSDKManagerEnum = require("Core.Service.SDKManager.NRCSDKManagerEnum")
local PlayerDataEvent = require("Data.Global.PlayerDataEvent")
local BattleUtils = require("NewRoco.Modules.Core.Battle.Common.BattleUtils")
local CommonUtils = require("NewRoco.Utils.CommonUtils")
local SceneUtils = require("NewRoco.Modules.Core.Scene.Common.SceneUtils")

local function OpenURLByPlatform(url)
  if RocoEnv.PLATFORM == "PLATFORM_OPENHARMONY" then
    UE4.UWebViewStatics.OpenURL(url, 2, false, true, "", false)
  else
    UE4.UWebViewStatics.OpenURL(url, 1, false, false, "", false)
  end
end

local UMG_SystemSettingMain_C = _G.NRCPanelBase:Extend("UMG_SystemSettingMain_C")
local _SoundConfigFilename = "NrcSoundConfig"
local EPermission = {
  WatchBattle = "WatchBattle",
  FriendSuggest = "FriendSuggest",
  FriendSearch = "FriendSearch",
  FriendAdd = "FriendAdd",
  FriendVisit = "FriendVisit"
}

function UMG_SystemSettingMain_C:OnConstruct()
  Log.Error("UMG_SystemSettingMain_C:OnConstruct1")
  _G.DataModelMgr.PlayerDataModel:AddPanelMusic(Enum.MusicApplyType.MAT_UI, Enum.InterfaceType.IT_SET)
  local StateGroup = _G.DataModelMgr.PlayerDataModel:GetStateGroupByApplyEnum(Enum.MusicApplyType.MAT_UI, Enum.InterfaceType.IT_SET)
  if StateGroup then
    _G.NRCAudioManager:BatchSetState(StateGroup)
  end
  self.Overridden.Construct(self)
  self.UpdateTime = 0
  self.QualityGroupTable = _G.DataConfigManager:GetTable(DataConfigManager.ConfigTableId.QUALITY_GROUP_SETTING_CONF):GetAllDatas()
  self:OnAddEventListener()
  self:SetCommonTitle()
  self.ButtonTypeToListWidget = {}
  self.ButtonTypeToListWidget[Enum.SettingButtonType.BUT_SYSTEM + 1] = self.SystemButtonList
  self.ButtonTypeToListWidget[Enum.SettingButtonType.BUT_CONTROL + 1] = self.OutsideKeyList
  self.ButtonTypeToListWidget[Enum.SettingButtonType.BUT_BATTLE + 1] = self.BattleKeyList
  self._permissionNotificationCheckID = nil
  self._permissionNotificationRequestID = nil
  self._permissionNotificationStatus = nil
  self.IsGetBindPhoneInfo = false
  self.PrivacyOptions = {
    {
      key = "ServiceProtocol",
      displayText = LuaText.privacy_setting_0,
      url = _G.DataConfigManager:GetGlobalConfigStrByKeyType("service_protocol_url", _G.DataConfigManager.ConfigTableId.GLOBAL_CONFIG, ""),
      func = self.OpenServiceProtocol
    },
    {
      key = "PrivacyProtect",
      displayText = LuaText.privacy_setting_1,
      url = _G.DataConfigManager:GetGlobalConfigStrByKeyType("privacy_protect_url", _G.DataConfigManager.ConfigTableId.GLOBAL_CONFIG, ""),
      func = self.OpenPrivacyProtect
    },
    {
      key = "ThirdInfoList",
      displayText = LuaText.privacy_setting_2,
      url = _G.DataConfigManager:GetGlobalConfigStrByKeyType("third_info_list_url", _G.DataConfigManager.ConfigTableId.GLOBAL_CONFIG, ""),
      func = self.OpenThirdInfoList
    },
    {
      key = "ChildrenProtect",
      displayText = LuaText.privacy_setting_3,
      url = _G.DataConfigManager:GetGlobalConfigStrByKeyType("children_protect_url", _G.DataConfigManager.ConfigTableId.GLOBAL_CONFIG, ""),
      func = self.OpenChildrenProtect
    },
    {
      key = "BeiAnUrl",
      displayText = LuaText.privacy_setting_6,
      url = _G.DataConfigManager:GetGlobalConfigStrByKeyType("bei_an_url", _G.DataConfigManager.ConfigTableId.GLOBAL_CONFIG, ""),
      func = self.OpenBeiAnUrl
    },
    {
      key = "CreditScoreWebView",
      displayText = LuaText.privacy_setting_4,
      url_windows = _G.DataConfigManager:GetGlobalConfigStrByKeyType("credit_score_web_view_windows_url", _G.DataConfigManager.ConfigTableId.GLOBAL_CONFIG, ""),
      url_mobile = _G.DataConfigManager:GetGlobalConfigStrByKeyType("credit_score_web_view_mobile_url", _G.DataConfigManager.ConfigTableId.GLOBAL_CONFIG, ""),
      func = self.OpenCreditScoreWebView
    },
    {
      key = "FamilyGuard",
      displayText = LuaText.privacy_setting_14,
      url_pub = _G.DataConfigManager:GetGlobalConfigStrByKeyType("family_guard_url_pub", _G.DataConfigManager.ConfigTableId.GLOBAL_CONFIG, ""),
      url_dev = _G.DataConfigManager:GetGlobalConfigStrByKeyType("family_guard_url_dev", _G.DataConfigManager.ConfigTableId.GLOBAL_CONFIG, ""),
      func = self.OnClickFamilyGuardGotoBtn
    },
    {
      key = "PrivacyHelper",
      displayText = LuaText.privacy_setting_7,
      url = _G.DataConfigManager:GetGlobalConfigStrByKeyType("privacy_helper_url", _G.DataConfigManager.ConfigTableId.GLOBAL_CONFIG, ""),
      func = self.OpenPrivacyHelper
    },
    {
      key = "CollectedPersonalInfoPage",
      displayText = LuaText.privacy_setting_50,
      url = _G.DataConfigManager:GetGlobalConfigStrByKeyType("privacy_setting_https", _G.DataConfigManager.ConfigTableId.GLOBAL_CONFIG, ""),
      func = self.OpenCollectedPersonalInfoPage
    },
    {
      key = "DeleteAccountPage",
      displayText = LuaText.privacy_setting_5,
      url_pub = _G.DataConfigManager:GetGlobalConfigStrByKeyType("delete_account_page_url_pub", _G.DataConfigManager.ConfigTableId.GLOBAL_CONFIG, ""),
      url_dev = _G.DataConfigManager:GetGlobalConfigStrByKeyType("delete_account_page_url_dev", _G.DataConfigManager.ConfigTableId.GLOBAL_CONFIG, ""),
      func = self.OpenDeleteAccountPage
    }
  }
  self:DynamicAddChildView(self.Privacy)
  self:DynamicAddChildView(self.Message)
  self:InitializeLogUploadSetting()
  Log.Error("UMG_SystemSettingMain_C:OnConstruct2")
end

function UMG_SystemSettingMain_C:OnDestruct()
  if self._permissionNotificationCheckID then
    UE.UNRCPermissionMgr.CancelIfRequestPermissionGrantedAsync(self._permissionNotificationCheckID)
    self._permissionNotificationCheckID = nil
  end
  if self._permissionNotificationRequestID then
    UE.UNRCPermissionMgr.CancelRequestPermissionCallback(self._permissionNotificationRequestID)
    self._permissionNotificationRequestID = nil
  end
  if self.DelayId then
    _G.DelayManager:CancelDelayById(self.DelayId)
    self.DelayId = nil
  end
end

function UMG_SystemSettingMain_C:OnUploadLogLevelChanged(Tag)
  local roleDataStr = _G.GEMPostManager:GetRoleDataForTLog()
  local detailsLog = "High" == Tag and 1 or 0
  local key = "LogLevelChangeFlow"
  local value = string.format("%s|%s|%s", key, roleDataStr, detailsLog)
  _G.GEMPostManager:SendNRCTLog(key, value)
end

function UMG_SystemSettingMain_C:InitializeLogUploadSetting()
  if self.LogCanvas then
    self.LogCanvas:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
  end
  if self.DeepLogsList then
    local List = self.DeepLogsList
    List:InitGridView({
      {
        Name = LuaText.repairtools_upload_2
      },
      {
        Name = LuaText.repairtools_upload_3
      }
    })
    local Tag2LogLevel = {Low = 0, High = 5}
    
    local function OnChangeLogLevel(Tag)
      local Level = Tag2LogLevel[Tag] or 0
      GameSetting:SetLogLevel(Level)
      GameSetting:SyncUploadLogTag(Tag)
      GameSetting:Save()
      self:RefreshLogLevels()
      self:OnUploadLogLevelChanged(Tag)
    end
    
    local function OnChangeToHighLogLevelConfirm(_, isOk)
      OnChangeLogLevel("High")
    end
    
    local function OnChangeToHighLogLevel()
      local Text = LuaText.repairtools_upload_6
      local Ctx = DialogContext()
      Ctx:SetTitle(LuaText.TIPS)
      Ctx:SetContent(Text)
      Ctx:SetMode(DialogContext.Mode.OK_CANCEL)
      Ctx:SetButtonText(LuaText.umg_dialog_2, LuaText.umg_dialog_1)
      Ctx:SetCloseOnCancel(true)
      Ctx:SetCallbackOkOnly(self, OnChangeToHighLogLevelConfirm)
      NRCModuleManager:DoCmd(TipsModuleCmd.Dialog_OpenDialog, Ctx)
    end
    
    local Low = List:GetItemByIndex(0)
    local High = List:GetItemByIndex(1)
    self.LogLevelButtons = {Low = Low, High = High}
    self:AddButtonListener(Low.Button, FPartial(OnChangeLogLevel, "Low"))
    self:AddButtonListener(High.Button, OnChangeToHighLogLevel)
    self:RefreshLogLevels()
  end
  if self.ManagementBtn then
    self:AddButtonListener(self.ManagementBtn.btnLevelUp, self.OnReqUploadLogs)
  end
  if self.BtnDetails_log and self.Details_log then
    self.BtnDetails_log:SetVisibility(UE.ESlateVisibility.SelfHitTestInvisible)
    self.Details_log:SetVisibility(UE.ESlateVisibility.Collapsed)
    self.Details_log.Title:SetText(LuaText.repairtools_upload_5)
    self:AddButtonListener(self.BtnDetails_log.btnLevelUp, self.OnShowLogTips)
  end
end

function UMG_SystemSettingMain_C:OnShowLogTips()
  self:ShowDetails("log")
end

function UMG_SystemSettingMain_C:OnReqUploadLogs()
  if _G.PlayerModuleCmd then
    local localPlayer = _G.NRCModuleManager:DoCmd(_G.PlayerModuleCmd.GET_LOCAL_PLAYER)
    if localPlayer and localPlayer.DumpCriticalVariables then
      localPlayer:DumpCriticalVariables()
    end
  end
  _G.NRCAudioManager:PlaySound2DAuto(1064, "UMG_RepairTools_C:OnCreateUploadLogs")
  NRCModuleManager:DoCmd(CosUploadModuleCmd.StartupUploadLogs)
end

function UMG_SystemSettingMain_C:RefreshLogLevels()
  if not self.LogLevelButtons then
    return
  end
  local TargetTag = GameSetting:GetUploadLogTag()
  for Tag, Button in pairs(self.LogLevelButtons) do
    local bSelected = Tag == TargetTag
    local bOldSelected = Button.bSelected
    local bChanged = bOldSelected ~= bSelected
    Button.bSelected = bSelected
    if bChanged then
      Button:OnItemSelected(bSelected)
    end
  end
end

function UMG_SystemSettingMain_C:OnActive(tabIndex, reqParam, PlayerSettingsRsp)
  UE4Helper.SetDesiredShowCursor(true, "UMG_SystemSettingMain_C")
  local NavigationMode = _G.DataModelMgr.PlayerDataModel:GetNavigationMode()
  local hasNavigation = _G.DataModelMgr.PlayerDataModel:GetNavigationMode()
  self.openPlayerSettingRsp = PlayerSettingsRsp
  if not NRCEnv:IsCreatePlayerMode() then
    self.Navigationmode:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
    local Padding = UE4.FMargin()
    Padding.Left = 88
    Padding.Top = -54
    Padding.Right = 0
    Padding.Bottom = 0
    self.ModeList.Slot:SetPadding(Padding)
    if not hasNavigation then
    elseif NavigationMode == ProtoEnum.NavigationModeType.NMT_COMPASS then
    elseif NavigationMode == ProtoEnum.NavigationModeType.NMT_MINIMAP then
    end
  else
    self.Navigationmode:SetVisibility(UE4.ESlateVisibility.Collapsed)
    local Padding = UE4.FMargin()
    Padding.Left = 88
    Padding.Top = 0
    Padding.Right = 0
    Padding.Bottom = 0
    self.ModeList.Slot:SetPadding(Padding)
  end
  self:CheckIsCreatePlayerLevel()
  self:InitSettingTab()
  self:InitUI(tabIndex)
  self:InitPrivacyInformationText()
  if not self.inInCreatePlayerLevel and _G.NRCModuleManager:DoCmd(_G.MainUIModuleCmd.ShouldDisableForNow) then
    _G.NRCModuleManager:DoCmd(_G.MainUIModuleCmd.OnLobbyMainInnerSubPanelLoaded)
  end
  self:RegisterEvent(self, SystemSettingModuleEvent.ClickButtonSettingListItem, self.OnClickButtonSettingListItem)
  self:RegisterEvent(self, SystemSettingModuleEvent.UpdateCustomMappingUI, self.UpdateCustomKeyMappingPage)
  self:RegisterEvent(self, SystemSettingModuleEvent.DetailTipsShowNotify, self.OnDetailTipsShowNotify)
  self:RegisterEvent(self, SystemSettingModuleEvent.GetUserSubscribeTplInfo, self.OnGetUserSubscribeTplInfo)
  self:RegisterEvent(self, SystemSettingModuleEvent.PlayerSettingUpdate, self.OnPlayerSettingUpdate)
  _G.NRCModuleManager:DoCmd(_G.SystemSettingModuleCmd.ReqQueryPlayerSettings)
  self.IsRepBindPhone = false
  _G.NRCModuleManager:DoCmd(_G.SystemSettingModuleCmd.ReqGetMobileBindInfo, true)
  _G.NRCModuleManager:DoCmd(_G.SystemSettingModuleCmd.ReqSecondaryPasswordGetInfo)
end

function UMG_SystemSettingMain_C:OnPlayerSettingUpdate()
  Log.Info("UMG_SystemSettingMain_C:OnPlayerSettingUpdate")
  self:SetUpNotificationList()
end

function UMG_SystemSettingMain_C:InitSettingTab()
  local Options = self.module.data:GetPrivacyConfigByKey("TabIcon").Options
  local optionList = {}
  for i, v in ipairs(Options) do
    if 7 == v.TabType then
      if RocoEnv.PLATFORM == "PLATFORM_WINDOWS" and not NRCEnv:IsCreatePlayerMode() then
        table.insert(optionList, v)
      end
    elseif 6 ~= v.TabType then
      table.insert(optionList, v)
    end
  end
  self.GridView_TabIcon:InitGridView(optionList)
end

function UMG_SystemSettingMain_C:InitPrivacyInformationText()
  local privacyText = ""
  local index = 1
  for _, v in pairs(self.PrivacyOptions) do
    if index > 1 then
      privacyText = privacyText .. "    " .. string.format("<a id=\"%s\">%s</>", v.displayText, v.key)
    else
      privacyText = string.format("<a id=\"%s\">%s</>", v.displayText, v.key)
    end
    index = index + 1
  end
  Log.Info("UMG_SystemSettingMain_C.InitPrivacyInformationText ", privacyText)
end

function UMG_SystemSettingMain_C:InitPrivacyTab()
end

function UMG_SystemSettingMain_C:SwitchCanBeSuggested(_can_be)
  if _G.FriendModuleCmd then
    _G.NRCModuleManager:DoCmd(_G.FriendModuleCmd.SetWhetherCanBeSuggested, _can_be)
  end
end

function UMG_SystemSettingMain_C:SwitchCanBeSearched(_can_be)
  if _G.FriendModuleCmd then
    _G.NRCModuleManager:DoCmd(_G.FriendModuleCmd.SetWhetherCanBeSearched, _can_be)
  end
end

function UMG_SystemSettingMain_C:OpenServiceProtocol(privacyOption)
  local url = privacyOption.url
  self:Log("UMG_SystemSettingMain_C.OpenServiceProtocol ", url)
  OpenURLByPlatform(url)
end

function UMG_SystemSettingMain_C:OpenPrivacyProtect(privacyOption)
  _G.NRCAudioManager:PlaySound2DAuto(1064, "UMG_SystemSettingMain_C:OpenServiceProtocol")
  local url = privacyOption.url
  self:Log("UMG_SystemSettingMain_C.OpenPrivacyProtect ", url)
  OpenURLByPlatform(url)
end

function UMG_SystemSettingMain_C:OpenChildrenProtect(privacyOption)
  local url = privacyOption.url
  OpenURLByPlatform(url)
end

function UMG_SystemSettingMain_C:OpenThirdInfoList(privacyOption)
  local url = privacyOption.url
  OpenURLByPlatform(url)
end

function UMG_SystemSettingMain_C:OpenBeiAnUrl(privacyOption)
  local url = privacyOption.url
  OpenURLByPlatform(url)
end

function UMG_SystemSettingMain_C:OpenCreditScoreWebView(privacyOption)
  _G.NRCSDKManager:OpenCreditScoreWebView()
end

function UMG_SystemSettingMain_C:OpenDeleteAccountPage(privacyOption)
  local url = RocoEnv.IS_SHIPPING and _G.AppMain:GetFormalPipeline() and privacyOption.url_pub or privacyOption.url_dev
  local userInfo = NRCModuleManager:DoCmd(OnlineModuleCmd.GetUserAccountInfo)
  local channelID = 0
  if userInfo.loginChannel then
    if string.lower(userInfo.loginChannel) == "wechat" then
      channelID = 1
    elseif string.lower(userInfo.loginChannel) == "qq" then
      channelID = 2
    end
  else
    Log.Error("OpenDeleteAccountPage with no channelID which is required")
    local DialogContext = require("NewRoco.Modules.System.TipsModule.DialogContext")
    local Context = DialogContext()
    Context:SetTitle(LuaText.umg_systemsettingmain_4):SetContent(LuaText.delete_account_tips):SetMode(DialogContext.Mode.OK):SetCloseOnOK(true):SetButtonText(LuaText.umg_systemsettingmain_5)
    return
  end
  local userInfoTable = {
    ADTAG = "client",
    msdkVersion = "V5",
    idType = "gopenid",
    os = (not RocoEnv.PLATFORM_ANDROID or not "1") and (not RocoEnv.PLATFORM_IOS or not "2") and (not RocoEnv.PLATFORM_WINDOWS or not "5") and RocoEnv.PLATFORM_OPENHARMONY and "11",
    gameid = "27819",
    channelid = channelID,
    outerIp = "127.0.0.1",
    webview = "msdk"
  }
  for key, value in pairs(userInfoTable) do
    url = url .. key .. "=" .. value .. "&"
  end
  url = string.sub(url, 1, -2)
  UE4.UWebViewStatics.OpenURL(url, 1, false, true, "", false)
end

function UMG_SystemSettingMain_C:OpenCollectedPersonalInfoPage(privacyOption)
  local url = privacyOption.url
  self:Log("UMG_SystemSettingMain_C.OpenCollectedPersonalInfoPage ", url)
  OpenURLByPlatform(url)
end

function UMG_SystemSettingMain_C:OnNavigationModeUpdate(mode, IsReConnect)
  if IsReConnect then
    return
  end
  if mode == ProtoEnum.NavigationModeType.NMT_COMPASS then
    local text = string.format(LuaText.setting_image_30, LuaText.navigation_mode_compass_name)
    _G.NRCModuleManager:DoCmd(TipsModuleCmd.TopHud_ShowTips, text)
  elseif mode == ProtoEnum.NavigationModeType.NMT_MINIMAP then
    local text = string.format(LuaText.setting_image_30, LuaText.navigation_mode_map_name)
    _G.NRCModuleManager:DoCmd(TipsModuleCmd.TopHud_ShowTips, text)
  end
end

function UMG_SystemSettingMain_C:ProcessDeleteAccountRes(webViewRet)
  if webViewRet.msgType == NRCSDKManagerEnum.WebViewMsgType.WebViewJsCall then
    local msgTable = JsonUtils.StringToJson(tostring(webViewRet.msgJsonData))
    if msgTable.type ~= nil and msgTable.type == "gacc:write_off_success" then
      Log.Debug("Delete Account success")
      self:BackToLogin()
    end
  end
end

function UMG_SystemSettingMain_C:OpenPrivacyHelper()
  _G.NRCSDKManager:OpenPrivacyHelper()
end

function UMG_SystemSettingMain_C:OnDeactive()
  UE4Helper.ReleaseDesiredShowCursor("UMG_SystemSettingMain_C")
  self:SaveSoundConfig()
  _G.DataModelMgr.PlayerDataModel:RemovePanelMusic(Enum.MusicApplyType.MAT_UI, Enum.InterfaceType.IT_SET)
  GlobalConfig.OpenMainPanelFromDebugBtn = 0
  _G.NRCEventCenter:UnRegisterEvent(self, SystemSettingModuleEvent.SetFpsItemSelect, self.SetFpsItemSelect)
  _G.NRCEventCenter:UnRegisterEvent(self, SystemSettingModuleEvent.SetMobileResolutionItemSelect, self.SetMobileResolutionItemSelect)
  _G.NRCEventCenter:UnRegisterEvent(self, SystemSettingModuleEvent.RefreshDropDownList, self.RefreshDropDownList)
  _G.NRCEventCenter:UnRegisterEvent(self, _G.NRCGlobalEvent.OnDisplayMetricsChanged, self.SetupDropDownList)
  _G.NRCEventCenter:UnRegisterEvent(self, SystemSettingModuleEvent.SecondPasswordStatusChangeEvent, self.RefreshSecondaryList)
  _G.NRCEventCenter:UnRegisterEvent(self, _G.NRCGlobalEvent.OnApplicationHasEnteredForeground, self.RefreshNotificationList)
  if self.module then
    self.module:UnRegisterEvent(self, SystemSettingModuleEvent.CloudMessageManagementBtnOKClicked)
  end
  self:UnRegisterEvent(self, SystemSettingModuleEvent.ClickButtonSettingListItem)
  self:UnRegisterEvent(self, SystemSettingModuleEvent.UpdateCustomMappingUI)
  self:UnRegisterEvent(self, SystemSettingModuleEvent.DetailTipsShowNotify)
  self:UnRegisterEvent(self, SystemSettingModuleEvent.PlayerSettingUpdate)
  _G.NRCSDKManager:RemoveEventListener(self, NRCSDKManagerEvent.OnWebViewOptNotify, self.ProcessDeleteAccountRes)
  _G.DataModelMgr.PlayerDataModel:RemoveEventListener(self, PlayerDataEvent.NAVIGATION_MODE_UPDATE, self.OnNavigationModeUpdate)
  if self.InformationManagementBtn and self.InformationManagementBtn.btnLevelUp then
    self:RemoveButtonListener(self.InformationManagementBtn.btnLevelUp)
  end
  _G.NRCSDKManager:SetQualityToApm()
  if self.mobileResolutionTimerId then
    _G.DelayManager:CancelDelayById(self.mobileResolutionTimerId)
  end
  _G.NRCEventCenter:UnRegisterEvent(self, SystemSettingModuleEvent.UnLockGetBindPhoneInfoReq, self.UnLockGetBindPhoneInfo)
end

function UMG_SystemSettingMain_C:OnPcClose()
  if self:GetVisibility() ~= UE4.ESlateVisibility.Visible and self:GetVisibility() ~= UE4.ESlateVisibility.SelfHitTestInvisible then
    return
  end
  self:OnCloseBtn()
end

function UMG_SystemSettingMain_C:OnAddEventListener()
  self:BtnDetailsInit()
  self:AddButtonListener(self.btnClose.btnClose, self.OnCloseBtn)
  self:AddButtonListener(self.HitTestBgBtn, self.OnHitTestBgBtn)
  self:AddButtonListener(self.HitTestBgBtn_1, self.OnHitTestBgBtn_1)
  self:AddButtonListener(self.HitTestBgBtn_2, self.OnHitTestBgBtn)
  self:AddButtonListener(self.HitTestBgBtn_3, self.OnHitTestBgBtn)
  self:AddButtonListener(self.OutOfStuckBtn.btnLevelUp, self.OnOutOfStuckBtnClick)
  self:AddButtonListener(self.DataRestoration.btnLevelUp, self.OnDataRestorationClick)
  if self.InformationManagementBtn and self.InformationManagementBtn.btnLevelUp then
    self:AddButtonListener(self.InformationManagementBtn.btnLevelUp, self.OnInformationManagementBtnClicked)
  end
  self:AddButtonListener(self.Btn_RestoreDefault.btnLevelUp, self.OnClickResetCustomKeyMapping)
  self:AddButtonListener(self.Button_ResetGraphic.btnLevelUp, self.OnClickResetGraphic)
  self:AddDelegateListener(self.Brightness.Slider.OnValueChanged, self.OnBrightSliderChanged)
  self:AddDelegateListener(self.Brightness.Slider.OnMouseCaptureEnd, self.OnBrightSliderEnd)
  self:RegisterEvent(self, SystemSettingModuleEvent.ChangeTabType, self.OnSelecedTabIndex)
  _G.NRCEventCenter:RegisterEvent("UMG_SystemSettingMain_C", self, SystemSettingModuleEvent.RefreshDropDownList, self.RefreshDropDownList)
  _G.NRCEventCenter:RegisterEvent("UMG_SystemSettingMain_C", self, SystemSettingModuleEvent.SetFpsItemSelect, self.SetFpsItemSelect)
  _G.NRCEventCenter:RegisterEvent("UMG_SystemSettingMain_C", self, SystemSettingModuleEvent.SetMobileResolutionItemSelect, self.SetMobileResolutionItemSelect)
  _G.NRCEventCenter:RegisterEvent("UMG_SystemSettingMain_C", self, _G.NRCGlobalEvent.OnDisplayMetricsChanged, self.SetupDropDownList)
  _G.NRCEventCenter:RegisterEvent("UMG_SystemSettingMain_C", self, SystemSettingModuleEvent.SecondPasswordStatusChangeEvent, self.RefreshSecondaryList)
  _G.NRCEventCenter:RegisterEvent("UMG_SystemSettingMain_C", self, NRCGlobalEvent.OnApplicationHasEnteredForeground, self.RefreshNotificationList)
  self.module:RegisterEvent(self, SystemSettingModuleEvent.CloudMessageManagementBtnOKClicked, self.OnCloudMessageManagementBtnOKClicked)
  _G.NRCSDKManager:AddEventListener(self, NRCSDKManagerEvent.OnWebViewOptNotify, self.ProcessDeleteAccountRes)
  _G.DataModelMgr.PlayerDataModel:AddEventListener(self, PlayerDataEvent.NAVIGATION_MODE_UPDATE, self.OnNavigationModeUpdate)
  _G.NRCEventCenter:RegisterEvent(self.name, self, SystemSettingModuleEvent.UnLockGetBindPhoneInfoReq, self.UnLockGetBindPhoneInfo)
end

function UMG_SystemSettingMain_C:BtnDetailsInit()
  local Table = _G.DataConfigManager:GetTable(DataConfigManager.ConfigTableId.QUALITY_GROUP_SETTING_CONF):GetAllDatas()
  local SelfHitTestInvisible = UE4.ESlateVisibility.SelfHitTestInvisible
  local FieldName1 = "BtnDetails_"
  local FieldName2 = "Details_"
  for index, config in pairs(Table) do
    if config.annotation then
      local Field1 = self[FieldName1 .. index]
      local Field2 = self[FieldName2 .. index]
      if Field1 and Field2 then
        local function Func(SystemSettingMain)
          SystemSettingMain:ShowDetails(index)
        end
        
        Field1.bShow = false
        Field1:SetVisibility(SelfHitTestInvisible)
        Field2.Title:SetText(config.annotation)
        self:AddButtonListener(Field1.btnLevelUp, Func)
      end
    end
  end
end

function UMG_SystemSettingMain_C:ShowDetails(Index)
  local Field1 = self["BtnDetails_" .. Index]
  local Field2 = self["Details_" .. Index]
  Field1.bShow = not Field1.bShow
  if Field1.bShow then
    self.SelectedDetailsIndex = Index
    Field1:PlayAnimation(Field1.Press)
    Field2:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
    self.HitTestBgBtn_1:SetVisibility(UE4.ESlateVisibility.Visible)
  else
    self.SelectedDetailsIndex = nil
    Field1:PlayAnimation(Field1.Up)
    Field2:SetVisibility(UE4.ESlateVisibility.Collapsed)
  end
end

function UMG_SystemSettingMain_C:OnHitTestBgBtn_1()
  if self.SelectedDetailsIndex then
    self:ShowDetails(self.SelectedDetailsIndex)
  end
  self.module:DispatchEvent(SystemSettingModuleEvent.CloseDetailTips)
  self.HitTestBgBtn_1:SetVisibility(UE4.ESlateVisibility.Collapsed)
end

function UMG_SystemSettingMain_C:InitUI(tabIndex)
  self.DropDownList = {}
  local num = self.GridView_TabIcon:GetItemCount()
  self.TabIcons = {}
  for i = 1, num do
    table.insert(self.TabIcons, self.GridView_TabIcon:GetItemByIndex(i - 1))
  end
  if 2 == GlobalConfig.OpenMainPanelFromDebugBtn then
    self:OnSelecedTabIndex(2, true)
  elseif 3 == GlobalConfig.OpenMainPanelFromDebugBtn then
    self:OnSelecedTabIndex(3, true)
  elseif 4 == GlobalConfig.OpenMainPanelFromDebugBtn then
    self:OnSelecedTabIndex(4, true)
  elseif 4 == GlobalConfig.OpenMainPanelFromDebugBtn then
    self:OnSelecedTabIndex(5, true)
  else
    self:OnSelecedTabIndex(1, true)
  end
  self.HitTestBgBtn:SetVisibility(UE4.ESlateVisibility.Collapsed)
  self.HitTestBgBtn_1:SetVisibility(UE4.ESlateVisibility.Collapsed)
  self:SetUpMainInfo()
  self:SetupDropDownList()
  if not self:IsPCMode() then
    self.loadCanvas:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
  else
    self.loadCanvas:SetVisibility(UE4.ESlateVisibility.Collapsed)
  end
  self:SetupSoundTab()
  self:SetLensTab()
  if tabIndex then
    self.GridView_TabIcon:SelectItemByIndex(tabIndex - 1)
    self.Switcher:SetActiveWidgetIndex(tabIndex - 1)
  else
    self.GridView_TabIcon:SelectItemByIndex(0)
    self.Switcher:SetActiveWidgetIndex(0)
  end
end

function UMG_SystemSettingMain_C:SetUpMainInfo()
  for i = 1, #self.TabIcons do
    local tabIconItem = self.TabIcons[i]
    if 1 == tabIconItem.TabType then
      local data = {
        itemTitle = LuaText.setting_image_37,
        itemType = 1,
        Call = self
      }
      self.Brightness:OnItemUpdate(data)
      local mapOptions = {}
      table.insert(mapOptions, {
        mapMode = ProtoEnum.NavigationModeType.NMT_MINIMAP
      })
      table.insert(mapOptions, {
        mapMode = ProtoEnum.NavigationModeType.NMT_COMPASS
      })
      local NavigationMode = _G.DataModelMgr.PlayerDataModel:GetNavigationMode()
      self.NavigationList:InitGridView(mapOptions)
      if NavigationMode == ProtoEnum.NavigationModeType.NMT_MINIMAP then
        self.NavigationList:SelectItemByIndex(0)
      elseif NavigationMode == ProtoEnum.NavigationModeType.NMT_COMPASS then
        self.NavigationList:SelectItemByIndex(1)
      end
      for j = 1, self.NavigationList:GetItemCount() do
        local item = self.NavigationList:GetItemByIndex(j - 1)
        item.bIsFirstSelect = false
      end
      local modeItemList = {}
      local joystickMode = _G.NRCModuleManager:DoCmd(MainUIModuleCmd.GetMoveJoystickMode)
      local joystickOptions = {}
      local joystickData = {}
      if joystickMode then
        table.insert(joystickOptions, {
          Name = _G.LuaText.joystick_mode_follow,
          Value = 0,
          bIsJoystickOption = true
        })
        table.insert(joystickOptions, {
          Name = _G.LuaText.joystick_mode_fixed,
          Value = 1,
          bIsJoystickOption = true
        })
        joystickData = {
          itemTitle = LuaText.setting_image_38,
          itemType = 3,
          Call = self,
          DropDownListInfo = joystickOptions,
          DropDownListKey = "joystickMode",
          DropDownListSelectValue = 1,
          CloseSelectionBtn = self.HitTestBgBtn,
          CloseAnnotationBtn = self.HitTestBgBtn_1
        }
      else
        table.insert(joystickOptions, {
          Name = _G.LuaText.joystick_mode_follow,
          Value = 0,
          bIsJoystickOption = true
        })
        table.insert(joystickOptions, {
          Name = _G.LuaText.joystick_mode_fixed,
          Value = 1,
          bIsJoystickOption = true
        })
        joystickData = {
          itemTitle = LuaText.setting_image_38,
          itemType = 3,
          Call = self,
          DropDownListInfo = joystickOptions,
          DropDownListKey = "joystickMode",
          DropDownListSelectValue = 0,
          CloseSelectionBtn = self.HitTestBgBtn,
          CloseAnnotationBtn = self.HitTestBgBtn_1
        }
      end
      if not self:IsPCMode() then
        table.insert(modeItemList, joystickData)
      end
      local propPlaceOptions = {}
      table.insert(propPlaceOptions, {
        Name = LuaText.prop_put_auto,
        Value = 0,
        bIsJoystickOption = true
      })
      table.insert(propPlaceOptions, {
        Name = LuaText.prop_put_free,
        Value = 1,
        bIsJoystickOption = true
      })
      local propPlaceData = {}
      local propPlaceMode = _G.NRCModuleManager:DoCmd(_G.MainUIModuleCmd.GetPropPlaceMode)
      propPlaceData = {
        itemTitle = LuaText.prop_put_set,
        itemType = 3,
        Call = self,
        DropDownListInfo = propPlaceOptions,
        DropDownListKey = "propPlaceMode",
        DropDownListSelectValue = propPlaceMode,
        CloseSelectionBtn = self.HitTestBgBtn,
        CloseAnnotationBtn = self.HitTestBgBtn_1
      }
      table.insert(modeItemList, propPlaceData)
      local level = UE4.UNRCQualityLibrary.GetFrameQuality()
      local selectIndex = 0
      local config = self.module.data:GetGraphicConfigByKey("FPS")
      local Options = self:CopyCurOptions(config.Options, UE4.UNRCQualityLibrary.GetCurMaxFrameQuality(), SystemSettingEnum.QualityID.FPS)
      local bPC = UE4Helper.IsPCMode()
      for j = #Options, 1, -1 do
        local Option = Options[j]
        if Option.bPC ~= nil and Option.bPC ~= bPC then
          table.remove(Options, j)
        end
      end
      for j, Option in ipairs(Options) do
        if Option.Value == level then
          selectIndex = level
        end
      end
      table.insert(modeItemList, {
        itemTitle = LuaText.setting_image_61,
        itemType = 3,
        Call = self,
        DropDownListInfo = Options,
        DropDownListKey = "FPS",
        DropDownListSelectValue = selectIndex,
        CloseSelectionBtn = self.HitTestBgBtn,
        CloseAnnotationBtn = self.HitTestBgBtn_1
      })
      if UE4Helper.IsPCMode() then
        local APIOptions = {
          {
            Name = LuaText.setting_image_73,
            Value = 0
          },
          {
            Name = LuaText.setting_image_82,
            Value = 1
          }
        }
        local apiSelectValue = UE4.UNRCQualityLibrary.IsPreferD3D12() and 1 or 0
        table.insert(modeItemList, {
          itemTitle = LuaText.setting_image_39,
          itemType = 3,
          Call = self,
          DropDownListInfo = APIOptions,
          DropDownListKey = "GraphicsAPI",
          DropDownListSelectValue = apiSelectValue,
          CloseSelectionBtn = self.HitTestBgBtn,
          CloseAnnotationBtn = self.HitTestBgBtn_1
        })
      else
      end
      local UnifiedDeviceLevel = UE4.UNRCQualityLibrary.GetUnifiedDeviceLevel()
      local DropDownListKey
      local Table = self.QualityGroupTable or _G.DataConfigManager:GetTable(DataConfigManager.ConfigTableId.QUALITY_GROUP_SETTING_CONF):GetAllDatas()
      local bShowItem = false
      if not self:IsPCMode() then
        if UnifiedDeviceLevel >= Table[SystemSettingEnum.QualityID.MobileResolution].Qualities[1].RequireUnifiedDeviceLevel and #Options > 1 then
          level = UE4.UNRCQualityLibrary.GetMobileResolutionQuality()
          selectIndex = 0
          config = self.module.data:GetGraphicConfigByKey("MobileResolution")
          Options = self:CopyCurOptions(config.Options, UE4.UNRCQualityLibrary.GetCurMaxMobileResolutionQuality(), SystemSettingEnum.QualityID.MobileResolution)
          selectIndex = level
          DropDownListKey = "MobileResolution"
          bShowItem = true
        end
      else
        bShowItem = true
        local ResolutionX, ResolutionY, CanUse = UE4.UNRCQualityLibrary.GetPCResolutionList()
        Options = {}
        local ResolutionName = {
          [1] = LuaText.setting_image_full_screen,
          [2] = LuaText.setting_image_full_screen,
          [3] = LuaText.setting_image_window
        }
        ResolutionX = ResolutionX:ToTable()
        ResolutionY = ResolutionY:ToTable()
        for j = 2, #ResolutionX do
          local Option = {}
          Option.Name = string.format("%d*%d %s", ResolutionX[j], ResolutionY[j], ResolutionName[j] or ResolutionName[3])
          Option.Value = j - 1
          table.insert(Options, Option)
        end
        local cur_x, cur_y, index = UE4.UNRCQualityLibrary.GetPCResolution()
        selectIndex = index
        DropDownListKey = "Resoluction"
      end
      if bShowItem then
        table.insert(modeItemList, {
          itemTitle = LuaText.setting_image_40,
          itemType = 3,
          Call = self,
          DropDownListInfo = Options,
          DropDownListKey = DropDownListKey,
          DropDownListSelectValue = selectIndex,
          CloseSelectionBtn = self.HitTestBgBtn,
          CloseAnnotationBtn = self.HitTestBgBtn_1
        })
      end
      self.ModeList:InitGridView(modeItemList)
      local settingItemList = {}
      local ImageQualityLevel = UE4.UNRCQualityLibrary.GetImageQuality()
      local devLevel = UE4.UNRCQualityLibrary.GetDefaultImageQuality()
      config = self.module.data:GetGraphicConfigByKey("ImageQuality")
      Options = self:CopyCurOptions(config.Options, UE4.UNRCQualityLibrary.GetCurMaxImageQuality(), SystemSettingEnum.QualityID.ImageQuality, UE4.ENRCImageQuality.Custom)
      for _, option in ipairs(Options) do
        if option.Value == devLevel then
          option.Recommend = true
        end
      end
      table.insert(settingItemList, {
        itemTitle = LuaText.setting_image_44,
        itemType = 3,
        Call = self,
        DropDownListInfo = Options,
        DropDownListKey = "ImageQuality",
        DropDownListSelectValue = ImageQualityLevel,
        CloseSelectionBtn = self.HitTestBgBtn,
        CloseAnnotationBtn = self.HitTestBgBtn_1
      })
      local QualityGroups = {}
      local QualityCfg = UE4.UNRCQualityLibrary.GetQualityConfigurations(ImageQualityLevel):ToTable()
      UnifiedDeviceLevel = UE4.UNRCQualityLibrary.GetUnifiedDeviceLevel()
      Table = self.QualityGroupTable or _G.DataConfigManager:GetTable(DataConfigManager.ConfigTableId.QUALITY_GROUP_SETTING_CONF):GetAllDatas()
      for j, _QualityTable in ipairs(Table) do
        if _QualityTable.groupName and _QualityTable.is_effect_quality and _QualityTable.is_effect_quality > 0 then
          local GroupName = _QualityTable.groupName
          if not bPC and "VsyncQuality" == GroupName then
          else
            local RequireUnifiedDeviceLevel = _QualityTable.Qualities[1] and _QualityTable.Qualities[1].RequireUnifiedDeviceLevel or 0
            config = self.module.data:GetGraphicConfigByKey(GroupName)
            if config then
              Options = config.Options
            else
              Options = {
                {
                  Name = LuaText.systemsettingmoduledata_4,
                  Value = 0
                },
                {
                  Name = LuaText.systemsettingmoduledata_5,
                  Value = 1
                },
                {
                  Name = LuaText.systemsettingmoduledata_6,
                  Value = 2
                },
                {
                  Name = LuaText.systemsettingmoduledata_16,
                  Value = 3
                }
              }
            end
            Options = self:CopyCurOptions(Options, UE4.UNRCQualityLibrary.GetCurMaxImageGroupQualityValue(GroupName), _QualityTable.id)
            if UnifiedDeviceLevel >= RequireUnifiedDeviceLevel and #Options > 1 then
              local QualityGroup = {}
              QualityGroup.caller = self
              QualityGroup.Name = _QualityTable.name
              QualityGroup.GroupName = GroupName
              QualityGroup.Options = Options
              QualityGroup.Annotation = _QualityTable.annotation
              QualityGroup.CloseSelectionBtn = self.HitTestBgBtn
              QualityGroup.CloseAnnotationBtn = self.HitTestBgBtn_1
              if ImageQualityLevel == UE4.ENRCImageQuality.Custom then
                QualityGroup.Level = UE4.UNRCQualityLibrary.GetGroupQualityLevel(GroupName) or 0
              else
                local optionValue = QualityCfg["sg." .. GroupName] or 0
                UE4.UNRCQualityLibrary.SetGroupQualityLevel(GroupName, optionValue)
                QualityGroup.Level = optionValue
              end
              QualityGroup.ShowPriority = _QualityTable.is_effect_quality
              table.insert(QualityGroups, QualityGroup)
            end
          end
        end
      end
      table.sort(QualityGroups, function(a, b)
        return a.ShowPriority < b.ShowPriority
      end)
      for _, qualityItem in ipairs(QualityGroups) do
        if not qualityItem.Level then
          qualityItem.Level = 0
        elseif qualityItem.GroupName == "EffectsQuality" then
          if 2 == qualityItem.Level then
            qualityItem.Level = 1
          end
        elseif qualityItem.GroupName == "ReflectionQuality" then
          qualityItem.Level = qualityItem.Level >= 2 and 2 or 0
        end
        if qualityItem.Name == "\229\143\141\229\176\132\232\180\168\233\135\143" then
          local function OnReflectionItemClicked(key, value)
            _G.NRCModuleManager:DoCmd(_G.SystemSettingModuleCmd.ApplyConfig, key, value)
          end
          
          local reflectionItemList = {}
          local reflectionItemListKey = self:GetReflectionItemListKey(qualityItem)
          table.insert(reflectionItemList, {
            btnText = LuaText.setting_image_33,
            selectHandler = FPartial(OnReflectionItemClicked, qualityItem.GroupName, qualityItem.Options[2].Value),
            Call = self
          })
          table.insert(reflectionItemList, {
            btnText = LuaText.setting_image_45,
            selectHandler = FPartial(OnReflectionItemClicked, qualityItem.GroupName, qualityItem.Options[1].Value),
            Call = self
          })
          if qualityItem.Annotation then
            table.insert(settingItemList, {
              itemTitle = qualityItem.Name,
              bNeedDescribe = true,
              describeText = qualityItem.Annotation,
              itemType = 4,
              Call = self,
              switchBtnListInfo = reflectionItemList,
              switchBtnListKey = reflectionItemListKey,
              CloseSelectionBtn = qualityItem.CloseSelectionBtn,
              CloseAnnotationBtn = qualityItem.CloseAnnotationBtn
            })
          else
            table.insert(settingItemList, {
              itemTitle = qualityItem.Name,
              itemType = 4,
              Call = self,
              switchBtnListInfo = reflectionItemList,
              switchBtnListKey = reflectionItemListKey,
              CloseSelectionBtn = qualityItem.CloseSelectionBtn,
              CloseAnnotationBtn = qualityItem.CloseAnnotationBtn
            })
          end
        elseif qualityItem.Name == "\230\138\151\233\148\175\233\189\191" then
          local DLSSConfig = JsonUtils.LoadSaved(_DLSSConfigFilename, {}) or {}
          local reflectionItemList = {}
          local reflectionItemListKey = DLSSConfig.AntiAliasing or 0
          
          local function OnAntiAliasingQualityItemClicked(bOpen)
            DLSSConfig = JsonUtils.LoadSaved(_DLSSConfigFilename, {}) or {}
            if bOpen then
              local antiAliasLevel = UE4.UNRCQualityLibrary.GetGroupQualityLevel(qualityItem.GroupName)
              UE4.UNRCQualityLibrary.SetImageQuality(UE4.ENRCImageQuality.Custom)
              UE4.UNRCQualityLibrary.SetGroupQualityLevel(qualityItem.GroupName, antiAliasLevel)
              DLSSConfig.AntiAliasing = 0
            else
              UE4.UNRCStatics.ExecConsoleCommand("r.MobileMSAA 1")
              DLSSConfig.AntiAliasing = 1
            end
            JsonUtils.DumpSaved(_DLSSConfigFilename, DLSSConfig)
            self:RefreshDropDownList()
          end
          
          table.insert(reflectionItemList, {
            btnText = LuaText.setting_image_33,
            selectHandler = FPartial(OnAntiAliasingQualityItemClicked, true),
            Call = self
          })
          table.insert(reflectionItemList, {
            btnText = LuaText.setting_image_45,
            selectHandler = FPartial(OnAntiAliasingQualityItemClicked, false),
            Call = self
          })
          table.insert(settingItemList, {
            itemTitle = LuaText.setting_image_46,
            itemType = 4,
            Call = self,
            switchBtnListInfo = reflectionItemList,
            switchBtnListKey = reflectionItemListKey,
            CloseSelectionBtn = qualityItem.CloseSelectionBtn,
            CloseAnnotationBtn = qualityItem.CloseAnnotationBtn
          })
          if qualityItem.Annotation then
            table.insert(settingItemList, {
              itemTitle = LuaText.setting_image_47,
              bNeedDescribe = true,
              describeText = qualityItem.Annotation,
              itemType = 3,
              Call = self,
              DropDownListInfo = qualityItem.Options,
              DropDownListKey = qualityItem.GroupName,
              DropDownListSelectValue = qualityItem.Level,
              CloseSelectionBtn = qualityItem.CloseSelectionBtn,
              CloseAnnotationBtn = qualityItem.CloseAnnotationBtn
            })
          else
            table.insert(settingItemList, {
              itemTitle = LuaText.setting_image_47,
              itemType = 3,
              Call = self,
              DropDownListInfo = qualityItem.Options,
              DropDownListKey = qualityItem.GroupName,
              DropDownListSelectValue = qualityItem.Level,
              CloseSelectionBtn = qualityItem.CloseSelectionBtn,
              CloseAnnotationBtn = qualityItem.CloseAnnotationBtn
            })
          end
        elseif qualityItem.Annotation then
          table.insert(settingItemList, {
            itemTitle = qualityItem.Name,
            bNeedDescribe = true,
            describeText = qualityItem.Annotation,
            itemType = 3,
            Call = self,
            DropDownListInfo = qualityItem.Options,
            DropDownListKey = qualityItem.GroupName,
            DropDownListSelectValue = qualityItem.Level,
            CloseSelectionBtn = qualityItem.CloseSelectionBtn,
            CloseAnnotationBtn = qualityItem.CloseAnnotationBtn
          })
        else
          table.insert(settingItemList, {
            itemTitle = qualityItem.Name,
            itemType = 3,
            Call = self,
            DropDownListInfo = qualityItem.Options,
            DropDownListKey = qualityItem.GroupName,
            DropDownListSelectValue = qualityItem.Level,
            CloseSelectionBtn = qualityItem.CloseSelectionBtn,
            CloseAnnotationBtn = qualityItem.CloseAnnotationBtn
          })
        end
      end
      self.ImageList:InitGridView(settingItemList)
      for j = 1, self.ImageList:GetItemCount() do
        local item = self.ImageList:GetItemByIndex(j - 1)
        if item.uiData.itemTitle == LuaText.setting_image_47 then
          local DLSSConfig = JsonUtils.LoadSaved(_DLSSConfigFilename, {}) or {}
          local bIsAntiAliasing = DLSSConfig.AntiAliasing or 0
          if 0 == bIsAntiAliasing then
            item:SetDisableGreyState(false)
          elseif 1 == bIsAntiAliasing then
            item:SetDisableGreyState(true)
          end
        end
      end
    elseif 2 == tabIconItem.TabType then
      local cameraItemList = {}
      table.insert(cameraItemList, {
        itemTitle = LuaText.umg_systemsettingmain_Lens3,
        itemType = 1,
        Call = self,
        sliderHandler = self.OnHorizontalLensChanged
      })
      table.insert(cameraItemList, {
        itemTitle = LuaText.umg_systemsettingmain_Lens4,
        itemType = 1,
        Call = self,
        sliderHandler = self.OnVerticalLensChanged
      })
      if self:IsPCMode() then
      elseif self.inInCreatePlayerLevel then
      else
        table.insert(cameraItemList, {
          itemTitle = LuaText.umg_systemsettingmain_Lens1,
          itemType = 1,
          Call = self,
          sliderHandler = self.OnHorizontalLensAimChanged
        })
        table.insert(cameraItemList, {
          itemTitle = LuaText.umg_systemsettingmain_Lens2,
          itemType = 1,
          Call = self,
          sliderHandler = self.OnVerticalLensAimChanged
        })
      end
      self.CameraList:InitGridView(cameraItemList)
    elseif 3 == tabIconItem.TabType then
      local soundItemList = {}
      table.insert(soundItemList, {
        itemTitle = LuaText.setting_image_48,
        itemType = 1,
        Call = self,
        sliderHandler = self.OnMainSoundChanged
      })
      table.insert(soundItemList, {
        itemTitle = LuaText.setting_image_65,
        itemType = 1,
        Call = self,
        sliderHandler = self.OnMusicSoundChanged
      })
      table.insert(soundItemList, {
        itemTitle = LuaText.setting_image_80,
        itemType = 1,
        Call = self,
        sliderHandler = self.OnEffectSoundChanged
      })
      table.insert(soundItemList, {
        itemTitle = LuaText.setting_image_84,
        itemType = 1,
        Call = self,
        sliderHandler = self.OnYellSoundChanged
      })
      if self:IsPCMode() then
        local soundMuteList = {}
        local soundConfig = JsonUtils.LoadSaved(_SoundConfigFilename, {})
        local soundMuteListKey = soundConfig.SoundMute or 1
        
        local function OnMusicMuteStateChanged(bIsOpen)
          if bIsOpen then
            soundConfig.SoundMute = 0
            _G.GlobalConfig.SoundMuteMode = true
            JsonUtils.DumpSaved(_SoundConfigFilename, soundConfig)
          else
            soundConfig.SoundMute = 1
            _G.GlobalConfig.SoundMuteMode = false
            JsonUtils.DumpSaved(_SoundConfigFilename, soundConfig)
          end
        end
        
        table.insert(soundMuteList, {
          btnText = LuaText.setting_image_33,
          selectHandler = FPartial(OnMusicMuteStateChanged, true),
          Call = self
        })
        table.insert(soundMuteList, {
          btnText = LuaText.setting_image_45,
          selectHandler = FPartial(OnMusicMuteStateChanged, false),
          Call = self
        })
        table.insert(soundItemList, {
          itemTitle = LuaText.mute_when_game_window_not_focused,
          switchBtnListInfo = soundMuteList,
          switchBtnListKey = soundMuteListKey,
          itemType = 4,
          Call = self,
          CloseSelectionBtn = self.HitTestBgBtn,
          CloseAnnotationBtn = self.HitTestBgBtn_1,
          parentList = self.PrivacyList
        })
      end
      self.SoundList:InitGridView(soundItemList)
    elseif 4 == tabIconItem.TabType then
      local accountInfo = {}
      local playerName = _G.DataModelMgr.PlayerDataModel:GetPlayerName()
      if NRCEnv:IsCreatePlayerMode() then
        playerName = nil
      end
      table.insert(accountInfo, {
        itemTitle = LuaText.setting_image_49,
        itemName = playerName,
        settingBtnText = LuaText.setting_image_66,
        bNeedSettingBtnIcon = true,
        settingBtnHandler = self.SwitchAccount,
        itemType = 2,
        Call = self,
        CloseSelectionBtn = self.HitTestBgBtn,
        CloseAnnotationBtn = self.HitTestBgBtn_1
      })
      self.AccountList:InitGridView(accountInfo)
      local otherItemList = {}
      local hideCdKey = _G.NRCModuleManager:DoCmd(_G.FunctionBanModuleCmd.CheckUIFunctionBan, _G.Enum.FunctionEntrance.FE_CDK, false)
      if not hideCdKey then
        table.insert(otherItemList, {
          itemTitle = LuaText.setting_image_50,
          settingBtnText = LuaText.setting_image_67,
          bNeedSettingBtnIcon = true,
          settingBtnHandler = self.OnCDKEYClick,
          itemType = 2,
          Call = self,
          CloseSelectionBtn = self.HitTestBgBtn,
          CloseAnnotationBtn = self.HitTestBgBtn_1
        })
      end
      table.insert(otherItemList, {
        itemTitle = LuaText.setting_image_17,
        settingBtnText = LuaText.setting_image_67,
        bNeedSettingBtnIcon = true,
        settingBtnHandler = self.OnCustomClicked,
        itemType = 2,
        Call = self,
        CloseSelectionBtn = self.HitTestBgBtn,
        CloseAnnotationBtn = self.HitTestBgBtn_1
      })
      table.insert(otherItemList, {
        itemTitle = LuaText.setting_image_18,
        settingBtnText = LuaText.setting_image_51,
        settingBtnHandler = self.OnReqUploadLogs,
        itemType = 2,
        Call = self,
        CloseSelectionBtn = self.HitTestBgBtn,
        CloseAnnotationBtn = self.HitTestBgBtn_1
      })
      local switchItemList = {}
      local Tag2LogLevel = {Low = 0, High = 5}
      
      local function RefreshLogLevels()
        local TargetTag = GameSetting:GetUploadLogTag()
        local deepLogItem = self.OthersList:GetItemByIndex(3)
        if "High" == TargetTag then
          deepLogItem:SelectSwitchBtnListByIndex(0)
        elseif "Low" == TargetTag then
          deepLogItem:SelectSwitchBtnListByIndex(1)
        end
      end
      
      local function OnChangeLogLevel(Tag)
        local Level = Tag2LogLevel[Tag] or 0
        GameSetting:SetLogLevel(Level)
        GameSetting:SyncUploadLogTag(Tag)
        GameSetting:Save()
        self:OnUploadLogLevelChanged(Tag)
      end
      
      local function OnChangeToHighLogLevelConfirm(listener, isOk)
        if isOk then
          OnChangeLogLevel("High")
        else
          RefreshLogLevels()
        end
      end
      
      local function OnChangeToHighLogLevel()
        local Text = LuaText.repairtools_upload_6
        local Ctx = DialogContext()
        Ctx:SetTitle(LuaText.TIPS)
        Ctx:SetContent(Text)
        Ctx:SetMode(DialogContext.Mode.OK_CANCEL)
        Ctx:SetButtonText(LuaText.umg_dialog_2, LuaText.umg_dialog_1)
        Ctx:SetClickAnywhereClose(true)
        Ctx:SetCloseOnCancel(true)
        Ctx:SetCallback(self, OnChangeToHighLogLevelConfirm)
        NRCModuleManager:DoCmd(TipsModuleCmd.Dialog_OpenDialog, Ctx)
      end
      
      local TargetTag = GameSetting:GetUploadLogTag()
      local switchKey = 0
      if "High" == TargetTag then
        switchKey = 0
      elseif "Low" == TargetTag then
        switchKey = 1
      end
      table.insert(switchItemList, {
        btnText = LuaText.repairtools_upload_3,
        selectHandler = OnChangeToHighLogLevel,
        Call = self
      })
      table.insert(switchItemList, {
        btnText = LuaText.repairtools_upload_2,
        selectHandler = FPartial(OnChangeLogLevel, "Low"),
        Call = self
      })
      table.insert(otherItemList, {
        itemTitle = LuaText.setting_image_19,
        bNeedDescribe = true,
        describeText = LuaText.repairtools_upload_5,
        switchBtnListInfo = switchItemList,
        switchBtnListKey = switchKey,
        itemType = 4,
        Call = self,
        CloseSelectionBtn = self.HitTestBgBtn,
        CloseAnnotationBtn = self.HitTestBgBtn_1
      })
      if not UE4Helper.IsPCMode() then
        local SleepSettingOptions = {}
        table.insert(SleepSettingOptions, {
          Name = _G.LuaText.Sleep2,
          Value = 0
        })
        table.insert(SleepSettingOptions, {
          Name = _G.LuaText.Sleep3,
          Value = 1
        })
        table.insert(SleepSettingOptions, {
          Name = _G.LuaText.Sleep4,
          Value = 2
        })
        table.insert(SleepSettingOptions, {
          Name = _G.LuaText.Sleep5,
          Value = 3
        })
        local sleepConfig = JsonUtils.LoadSaved(_SleepConfigFilename, {}) or {}
        local secs = sleepConfig.sleepIntervalSeconds or 600
        local sleepSelectIndex = 1
        if 600 == secs then
          sleepSelectIndex = 0
        elseif 1200 == secs then
          sleepSelectIndex = 1
        elseif 1800 == secs then
          sleepSelectIndex = 2
        elseif 0 == secs then
          sleepSelectIndex = 3
        end
        table.insert(otherItemList, {
          itemTitle = _G.LuaText.Sleep1,
          settingBtnText = "",
          itemType = 3,
          DropDownListInfo = SleepSettingOptions,
          DropDownListKey = "SleepSetting",
          Call = self,
          CloseSelectionBtn = self.HitTestBgBtn,
          CloseAnnotationBtn = self.HitTestBgBtn_1,
          DropDownListSelectValue = sleepSelectIndex
        })
      end
      self.OthersList:InitGridView(otherItemList)
    elseif 5 == tabIconItem.TabType then
      local personalList = {}
      if _G.CommonPopUpModuleCmd and _G.FriendModuleCmd then
        table.insert(personalList, {
          itemTitle = LuaText.setting_image_20,
          settingBtnText = LuaText.setting_image_53,
          bNeedSettingBtnIcon = true,
          settingBtnHandler = self.OnInformationManagementBtnClicked,
          itemType = 2,
          Call = self,
          CloseSelectionBtn = self.HitTestBgBtn,
          CloseAnnotationBtn = self.HitTestBgBtn_1
        })
      end
      local hideBindPhone = _G.NRCModuleManager:DoCmd(_G.FunctionBanModuleCmd.CheckUIFunctionBan, _G.Enum.FunctionEntrance.FE_BIND_PHONE, false)
      if not hideBindPhone then
        if self.IsRepBindPhone then
          local phoneInfo = _G.DataModelMgr.PlayerDataModel:GetPlayerMobileBindInfo()
          if phoneInfo and phoneInfo.mobile_num and "" ~= phoneInfo.mobile_num then
            table.insert(personalList, {
              itemTitle = LuaText.setting_image_21,
              settingBtnText = LuaText.setting_image_69,
              itemName = self.module.data:GetEncryptPhoneNum(phoneInfo.mobile_num),
              bNeedSettingBtnIcon = true,
              settingBtnHandler = self.OnBindPhone,
              itemType = 2,
              Call = self,
              CloseSelectionBtn = self.HitTestBgBtn,
              CloseAnnotationBtn = self.HitTestBgBtn_1
            })
          else
            table.insert(personalList, {
              itemTitle = LuaText.setting_image_21,
              settingBtnText = LuaText.setting_image_81,
              itemName = LuaText.Setting_UnBound_Phone_Tips,
              bNeedSettingBtnIcon = true,
              settingBtnHandler = self.OnBindPhone,
              itemType = 2,
              Call = self,
              CloseSelectionBtn = self.HitTestBgBtn,
              CloseAnnotationBtn = self.HitTestBgBtn_1
            })
          end
        else
          table.insert(personalList, {
            itemTitle = LuaText.setting_image_21,
            settingBtnText = LuaText.setting_image_81,
            itemName = LuaText.Bind_Phone_Tips,
            bNeedSettingBtnIcon = true,
            settingBtnHandler = self.OnBindPhone,
            itemType = 2,
            Call = self,
            CloseSelectionBtn = self.HitTestBgBtn,
            CloseAnnotationBtn = self.HitTestBgBtn_1,
            IsHideBtn = true
          })
        end
      end
      self.PersonalList:InitGridView(personalList)
      local playerLv = _G.DataModelMgr.PlayerDataModel:GetPlayerLevel()
      local limitLevel = _G.DataConfigManager:GetActivityGlobalConfig("secondary_password_unlocks_level_restriction").num
      if playerLv >= limitLevel then
        self.SecondaryPassword:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
        local secondaryList = {}
        local secondaryPasswordInfo = _G.NRCModuleManager:DoCmd(_G.SystemSettingModuleCmd.GetSecondaryPasswordInfo)
        self.SecondaryTextTips:SetText(LuaText.secondary_pwd_setup_panel_guide)
        if secondaryPasswordInfo then
          local secondarySwitchItemList = {}
          local titleText = ""
          local switchKey = 0
          local timeStamp = secondaryPasswordInfo.status_timestamp
          if secondaryPasswordInfo.status then
            if secondaryPasswordInfo.status == ProtoEnum.SecondaryPasswordStatus.SPS_None or secondaryPasswordInfo.status == ProtoEnum.SecondaryPasswordStatus.SPS_Unset then
              titleText = LuaText.setting_image_55
              switchKey = 1
            elseif secondaryPasswordInfo.status == ProtoEnum.SecondaryPasswordStatus.SPS_Set or secondaryPasswordInfo.status == ProtoEnum.SecondaryPasswordStatus.SPS_Disable or secondaryPasswordInfo.status == ProtoEnum.SecondaryPasswordStatus.SPS_Waiting or secondaryPasswordInfo.status == ProtoEnum.SecondaryPasswordStatus.SPS_Free then
              titleText = LuaText.setting_image_70
              switchKey = 0
            end
          end
          
          local function OnOpenSecondaryPasswordSetClicked()
            _G.NRCModuleManager:DoCmd(_G.SystemSettingModuleCmd.OpenSecondaryPasswordSet)
          end
          
          local function OnCloseSecondaryPasswordSetClicked()
            _G.NRCModuleManager:DoCmd(_G.SystemSettingModuleCmd.OpenSecondaryPasswordCancel)
          end
          
          table.insert(secondarySwitchItemList, {
            btnText = LuaText.setting_image_33,
            selectHandler = OnOpenSecondaryPasswordSetClicked,
            Call = self
          })
          table.insert(secondarySwitchItemList, {
            btnText = LuaText.setting_image_45,
            selectHandler = OnCloseSecondaryPasswordSetClicked,
            Call = self
          })
          table.insert(secondaryList, {
            itemTitle = titleText,
            switchBtnListInfo = secondarySwitchItemList,
            switchBtnListKey = switchKey,
            itemType = 4,
            Call = self,
            CloseSelectionBtn = self.HitTestBgBtn,
            CloseAnnotationBtn = self.HitTestBgBtn_1
          })
          
          local function OnOpenSecondaryPasswordModify()
            _G.NRCModuleManager:DoCmd(_G.SystemSettingModuleCmd.OpenSecondaryPasswordModify)
          end
          
          if secondaryPasswordInfo.status and secondaryPasswordInfo.status == ProtoEnum.SecondaryPasswordStatus.SPS_Set or secondaryPasswordInfo.status == ProtoEnum.SecondaryPasswordStatus.SPS_Disable or secondaryPasswordInfo.status == ProtoEnum.SecondaryPasswordStatus.SPS_Waiting or secondaryPasswordInfo.status == ProtoEnum.SecondaryPasswordStatus.SPS_Free then
            table.insert(secondaryList, {
              itemTitle = LuaText.setting_image_79,
              settingBtnText = LuaText.setting_image_77,
              bNeedSettingBtnIcon = true,
              settingBtnHandler = OnOpenSecondaryPasswordModify,
              itemType = 2,
              Call = self,
              CloseSelectionBtn = self.HitTestBgBtn,
              CloseAnnotationBtn = self.HitTestBgBtn_1
            })
          end
          
          local function OnOpenSecondaryPasswordCancelForceDisable()
            _G.NRCModuleManager:DoCmd(_G.SystemSettingModuleCmd.OpenSecondaryPasswordCancelForceDisable)
          end
          
          if secondaryPasswordInfo.status and secondaryPasswordInfo.status == ProtoEnum.SecondaryPasswordStatus.SPS_Disable then
            table.insert(secondaryList, {
              itemTitle = LuaText.setting_image_85,
              settingBtnText = LuaText.setting_image_86,
              settingBtnHandler = OnOpenSecondaryPasswordCancelForceDisable,
              countDownTimeStamp = timeStamp,
              isSecondaryPasswordCountdown = true,
              itemType = 2,
              Call = self,
              CloseSelectionBtn = self.HitTestBgBtn,
              CloseAnnotationBtn = self.HitTestBgBtn_1
            })
          end
          self.SecondaryList:InitGridView(secondaryList)
        end
      else
        self.SecondaryPassword:SetVisibility(UE4.ESlateVisibility.Collapsed)
      end
      if self.openPlayerSettingRsp and 0 == self.openPlayerSettingRsp.ret_info.ret_code then
        self:OnQueryPlayerSettingsRsp(self.openPlayerSettingRsp)
      else
        local req = _G.ProtoMessage:newZoneQueryPlayerSettingsReq()
        _G.ZoneServer:SendWithHandler(_G.ProtoCMD.ZoneSvrCmd.ZONE_QUERY_PLAYER_SETTINGS_REQ, req, self, self.OnQueryPlayerSettingsRsp, false, true)
      end
      local policyList = {}
      local privacyText = ""
      local index = 1
      for _, v in pairs(self.PrivacyOptions) do
        if index > 1 then
          privacyText = privacyText .. "    " .. string.format("<a id=\"%s\">%s</>", v.displayText, v.key)
        else
          privacyText = string.format("<a id=\"%s\">%s</>", v.displayText, v.key)
        end
        table.insert(policyList, {
          privacyText = v.displayText,
          privacyType = 0,
          key = v.key,
          Caller = self,
          PrivacyOptions = self.PrivacyOptions
        })
        index = index + 1
      end
      self.PolicyList:InitGridView(policyList)
    elseif 6 == tabIconItem.TabType then
    elseif 7 == tabIconItem.TabType then
    end
  end
  local DeviceLoadPercent = UE4.UNRCQualityLibrary.GetDeviceLoad() / 100
  self.LoadSchedule:SetPercent(DeviceLoadPercent)
  if DeviceLoadPercent < 0.66 then
    self.overload:SetText(LuaText.setting_image_fluency)
    self.overload:SetColorAndOpacity(UE4.UNRCStatics.HexToSlateColor("70c800"))
    self.LoadSchedule:SetFillColorAndOpacity(UE4.UNRCStatics.HexToLinearColor("70c800"))
  else
    self.overload:SetText(LuaText.setting_image_overload)
    self.overload:SetColorAndOpacity(UE4.UNRCStatics.HexToSlateColor("AF3D3EFF"))
    self.LoadSchedule:SetFillColorAndOpacity(UE4.UNRCStatics.HexToLinearColor("AF3D3EFF"))
  end
  self:SetDropDownList()
end

function UMG_SystemSettingMain_C:GetReflectionItemListKey(reflectionItem)
  local inValue = self:GetLegalLevel(reflectionItem.GroupName, reflectionItem.Level)
  local index = self:FindOptionIndexByValue(reflectionItem.Options, inValue)
  local key = self:GetSelectedOptionIndex(reflectionItem.Options[index], reflectionItem.Options)
  if 1 == key then
    return 1
  elseif 2 == key then
    return 0
  end
end

function UMG_SystemSettingMain_C:FindOptionIndexByValue(Options, inValue)
  for index, option in ipairs(Options) do
    if option.Value == inValue then
      return index
    end
  end
  return 1
end

function UMG_SystemSettingMain_C:GetLegalLevel(Name, Level)
  if not Level then
    return 0
  end
  if "EffectsQuality" == Name then
    if 2 == Level then
      return 1
    end
  elseif "ReflectionQuality" == Name then
    Level = Level >= 2 and 2 or 0
  elseif "AntiAliasingQuality" == Name then
    Level = Level >= 2 and 2 or 0
  end
  return Level
end

function UMG_SystemSettingMain_C:GetSelectedOptionIndex(optionData, Options)
  local index = self:FindOptionIndex(optionData, Options)
  return index
end

function UMG_SystemSettingMain_C:FindOptionIndex(inOption, Options)
  for index, option in ipairs(Options) do
    if option == inOption then
      return index
    end
  end
  return 1
end

function UMG_SystemSettingMain_C:SetDropDownList()
  for i = 1, self.ModeList:GetItemCount() do
    local item = self.ModeList:GetItemByIndex(i - 1)
    if 3 == item.uiData.itemType then
      table.insert(self.DropDownList, item.DropDownList)
    end
  end
  for i = 1, self.ImageList:GetItemCount() do
    local item = self.ImageList:GetItemByIndex(i - 1)
    if 3 == item.uiData.itemType then
      table.insert(self.DropDownList, item.DropDownList)
    end
  end
end

function UMG_SystemSettingMain_C:GetModeListItemByDropDownListKey(DropDownListKey)
  for i = 1, self.ModeList:GetItemCount() do
    local item = self.ModeList:GetItemByIndex(i - 1)
    if item.uiData.DropDownListKey == DropDownListKey then
      return item
    end
  end
end

function UMG_SystemSettingMain_C:OnQueryPlayerSettingsRsp(rsp)
  if 0 ~= rsp.ret_info.ret_code then
    Log.Error("\230\159\165\232\175\162\231\142\169\229\174\182\232\174\190\231\189\174\229\164\177\232\180\165", table.tostring(rsp))
  else
    local settings = rsp.settings
    local defaultPlayerSettings = _G.NRCModuleManager:DoCmd(_G.SystemSettingModuleCmd.GetPlayerSettings)
    local privacyList = {}
    if not RocoEnv.PLATFORM_WINDOWS then
      table.insert(privacyList, {
        itemTitle = LuaText.setting_image_23,
        settingBtnText = LuaText.setting_image_71,
        bNeedSettingBtnIcon = true,
        settingBtnHandler = self.OpenPrivilegeAuthorization,
        itemType = 2,
        Call = self,
        CloseSelectionBtn = self.HitTestBgBtn,
        CloseAnnotationBtn = self.HitTestBgBtn_1,
        parentList = self.PrivacyList
      })
    end
    if not NRCEnv:IsCreatePlayerMode() then
      local privacyItemList = {}
      local privacyItemListKey = 0
      if defaultPlayerSettings then
        local pvp = defaultPlayerSettings and defaultPlayerSettings.pvp
        local observeBattle = pvp and pvp.observe_battle
        local deny = observeBattle and observeBattle.deny
        local allow = not deny
        if allow then
          privacyItemListKey = 0
        else
          privacyItemListKey = 1
        end
      else
        privacyItemListKey = 0
      end
      
      local function OnWatchBattleCheckStateChanged(bIsOpen)
        local nextAllowFriendWatchBattle = bIsOpen and true or false
        local prevPlayerSettings = _G.NRCModuleManager:DoCmd(_G.SystemSettingModuleCmd.GetPlayerSettings)
        local nextPlayerSettings = BattleUtils.ModifyAllowObserveInPlayerSettings(prevPlayerSettings, nextAllowFriendWatchBattle)
        if prevPlayerSettings ~= nextPlayerSettings then
          _G.NRCModuleManager:DoCmd(_G.SystemSettingModuleCmd.ReqModifyPlayerSettings, nextPlayerSettings)
        end
      end
      
      table.insert(privacyItemList, {
        btnText = LuaText.setting_image_33,
        selectHandler = FPartial(OnWatchBattleCheckStateChanged, true),
        Call = self
      })
      table.insert(privacyItemList, {
        btnText = LuaText.setting_image_45,
        selectHandler = FPartial(OnWatchBattleCheckStateChanged, false),
        Call = self
      })
      table.insert(privacyList, {
        itemTitle = LuaText.setting_image_24,
        bNeedDescribe = true,
        describeText = LuaText.privacy_setting_35,
        switchBtnListInfo = privacyItemList,
        switchBtnListKey = privacyItemListKey,
        itemType = 4,
        Call = self,
        CloseSelectionBtn = self.HitTestBgBtn,
        CloseAnnotationBtn = self.HitTestBgBtn_1,
        parentList = self.PrivacyList
      })
      local privacyItemList1 = {}
      local privacyItemList1Key = 0
      if settings.friendship then
        if settings.friendship.can_be_searched then
          privacyItemList1Key = 0
        else
          privacyItemList1Key = 1
        end
      else
        privacyItemList1Key = 0
      end
      
      local function OnFriendSearchStateChanged(bIsOpen)
        if _G.FriendModuleCmd then
          _G.NRCModuleManager:DoCmd(_G.FriendModuleCmd.SetWhetherCanBeSearched, bIsOpen)
        end
      end
      
      table.insert(privacyItemList1, {
        btnText = LuaText.setting_image_33,
        selectHandler = FPartial(OnFriendSearchStateChanged, true),
        Call = self
      })
      table.insert(privacyItemList1, {
        btnText = LuaText.setting_image_45,
        selectHandler = FPartial(OnFriendSearchStateChanged, false),
        Call = self
      })
      table.insert(privacyList, {
        itemTitle = LuaText.setting_image_25,
        bNeedDescribe = true,
        describeText = LuaText.privacy_setting_8,
        switchBtnListInfo = privacyItemList1,
        switchBtnListKey = privacyItemList1Key,
        itemType = 4,
        Call = self,
        CloseSelectionBtn = self.HitTestBgBtn,
        CloseAnnotationBtn = self.HitTestBgBtn_1,
        parentList = self.PrivacyList
      })
      local privacyItemList2 = {}
      local privacyItemList2Key = 0
      if settings.friendship then
        if settings.friendship.can_be_sugguested then
          privacyItemList2Key = 0
        else
          privacyItemList2Key = 1
        end
      else
        privacyItemList2Key = 0
      end
      
      local function OnFriendSuggestCheckStateChanged(bIsOpen)
        if _G.FriendModuleCmd then
          _G.NRCModuleManager:DoCmd(_G.FriendModuleCmd.SetWhetherCanBeSuggested, bIsOpen)
        end
      end
      
      table.insert(privacyItemList2, {
        btnText = LuaText.setting_image_33,
        selectHandler = FPartial(OnFriendSuggestCheckStateChanged, true),
        Call = self
      })
      table.insert(privacyItemList2, {
        btnText = LuaText.setting_image_45,
        selectHandler = FPartial(OnFriendSuggestCheckStateChanged, false),
        Call = self
      })
      table.insert(privacyList, {
        itemTitle = LuaText.setting_image_26,
        bNeedDescribe = true,
        describeText = LuaText.privacy_setting_9,
        switchBtnListInfo = privacyItemList2,
        switchBtnListKey = privacyItemList2Key,
        itemType = 4,
        Call = self,
        CloseSelectionBtn = self.HitTestBgBtn,
        CloseAnnotationBtn = self.HitTestBgBtn_1,
        parentList = self.PrivacyList
      })
      local privacyItemList3 = {}
      local privacyItemList3Key = 0
      if settings.friendship then
        if settings.friendship.can_be_add_friend then
          privacyItemList3Key = 0
        else
          privacyItemList3Key = 1
        end
      else
        privacyItemList3Key = 0
      end
      
      local function OnFriendAddCheckStateChanged(bIsOpen)
        if _G.FriendModuleCmd then
          _G.NRCModuleManager:DoCmd(_G.FriendModuleCmd.SetWhetherCanStrangerAdd, bIsOpen)
        end
      end
      
      table.insert(privacyItemList3, {
        btnText = LuaText.setting_image_33,
        selectHandler = FPartial(OnFriendAddCheckStateChanged, true),
        Call = self
      })
      table.insert(privacyItemList3, {
        btnText = LuaText.setting_image_45,
        selectHandler = FPartial(OnFriendAddCheckStateChanged, false),
        Call = self
      })
      table.insert(privacyList, {
        itemTitle = LuaText.setting_image_27,
        bNeedDescribe = true,
        describeText = LuaText.privacy_setting_38,
        switchBtnListInfo = privacyItemList3,
        switchBtnListKey = privacyItemList3Key,
        itemType = 4,
        Call = self,
        CloseSelectionBtn = self.HitTestBgBtn,
        CloseAnnotationBtn = self.HitTestBgBtn_1,
        parentList = self.PrivacyList
      })
      local privacyItemList5 = {}
      local privacyItemList5Key = 0
      if settings.recommendations then
        if true == settings.recommendations.friend_pr then
          privacyItemList5Key = 0
        elseif settings.recommendations.friend_pr == false then
          privacyItemList5Key = 1
        else
          privacyItemList5Key = 0
        end
      else
        privacyItemList5Key = 0
      end
      
      local function OnRecommendStateChanged(bIsOpen)
        if bIsOpen then
          if _G.FriendModuleCmd then
            _G.NRCModuleManager:DoCmd(_G.FriendModuleCmd.SetWhetherCanPersonalRecommend, bIsOpen)
          end
        else
          if not CommonPopUpModuleCmd then
            return
          end
          local CommonPopUpData = _G.NRCCommonPopUpData()
          CommonPopUpData.RemindSwitch = 0
          CommonPopUpData.ContentText = LuaText.setting_personalized_recommendations_close
          CommonPopUpData.TitleText = LuaText.umg_systemsettingmain_4
          CommonPopUpData.Btn_LeftText = LuaText.CANCEL
          CommonPopUpData.Btn_RightText = LuaText.umg_bag_popup_2
          CommonPopUpData.Call = self
          CommonPopUpData.Btn_RightHandler = self.ClosePersonalRecommend
          CommonPopUpData.Btn_LeftHandler = self.PersonalRecommedPopUpCloseCallback
          CommonPopUpData.Btn_CloseHandler = self.PersonalRecommedPopUpCloseCallback
          CommonPopUpData.ClosePanelHandler = self.PersonalRecommedPopUpCloseCallback
          _G.NRCModeManager:DoCmd(CommonPopUpModuleCmd.OpenRemindPanel, CommonPopUpData)
        end
      end
      
      table.insert(privacyItemList5, {
        btnText = LuaText.setting_image_33,
        selectHandler = FPartial(OnRecommendStateChanged, true),
        Call = self
      })
      table.insert(privacyItemList5, {
        btnText = LuaText.setting_image_45,
        selectHandler = FPartial(OnRecommendStateChanged, false),
        Call = self
      })
      table.insert(privacyList, {
        itemTitle = LuaText.setting_image_28,
        bNeedDescribe = true,
        describeText = LuaText.setting_personalized_recommendations_tips,
        switchBtnListInfo = privacyItemList5,
        switchBtnListKey = privacyItemList5Key,
        itemType = 4,
        Call = self,
        CloseSelectionBtn = self.HitTestBgBtn,
        CloseAnnotationBtn = self.HitTestBgBtn_1,
        parentList = self.PrivacyList
      })
    end
    self.PrivacyList:InitGridView(privacyList)
    self:SetUpNotificationList()
  end
end

function UMG_SystemSettingMain_C:ClosePersonalRecommend()
  _G.NRCModuleManager:DoCmd(_G.FriendModuleCmd.SetWhetherCanPersonalRecommend, false)
end

function UMG_SystemSettingMain_C:PersonalRecommedPopUpCloseCallback()
  for i = 1, self.PrivacyList:GetItemCount() do
    local item = self.PrivacyList:GetItemByIndex(i - 1)
    if item.uiData.itemTitle == LuaText.setting_image_28 then
      if item:IsSwtichBtnSelected(0) then
        item:RefreshSwitchBtnList(1)
        break
      end
      item:RefreshSwitchBtnList(0)
      break
    end
  end
end

function UMG_SystemSettingMain_C:OpenPrivilegeAuthorization()
  Log.Info("UMG_SystemSettingMain_C:OpenPrivilegeAuthorization")
  _G.NRCAudioManager:PlaySound2DAuto(41401003, "UMG_SystemSettingMain_C:OpenPrivilegeAuthorization")
  _G.NRCModuleManager:DoCmd(_G.SystemSettingModuleCmd.OpenPrivilegeAuthorizationPopUp)
end

function UMG_SystemSettingMain_C:OpenUserSubscribeTpl()
  _G.NRCAudioManager:PlaySound2DAuto(41401003, "UMG_SystemSettingMain_C:OpenUserSubscribeTpl")
  local tpl = {
    Enum.UserSubscribeTplType.USER_SUBSCRIBE_TPL_TYPE_ACT,
    Enum.UserSubscribeTplType.USER_SUBSCRIBE_TPL_TYPE_FRIEND,
    Enum.UserSubscribeTplType.USER_SUBSCRIBE_TPL_TYPE_FUNC
  }
  local need_open_link = 1
  _G.NRCModuleManager:DoCmd(_G.SystemSettingModuleCmd.ReqGetUserSubscribeTplInfo, tpl, need_open_link)
end

function UMG_SystemSettingMain_C:OnGetUserSubscribeTplInfo(rsp)
  if rsp.openlink and string.len(rsp.openlink) > 0 then
    Log.Info("openlink", rsp.openlink)
    local screenType = 2
    if RocoEnv.PLATFORM == "PLATFORM_WINDOWS" then
      screenType = 1
    end
    local isFullScreen = false
    local isUseURLEncode = true
    local entraJson = ""
    local bIsBrowser = false
    UE4.UWebViewStatics.OpenURL(rsp.openlink, screenType, isFullScreen, isUseURLEncode, entraJson, bIsBrowser)
  end
end

local function OnUserSubscribeChanged(self, data, bIsOpen)
  Log.Info("UMG_MessageSettingList_C.OnUserSubscribeChanged", data.Name, bIsOpen)
  local playerSettings = _G.NRCModuleManager:DoCmd(_G.SystemSettingModuleCmd.GetPlayerSettings)
  local newPlayerSettings = {}
  if playerSettings then
    table.deepCopy(playerSettings, newPlayerSettings)
  end
  if newPlayerSettings.userSubscribe then
    if data.UniqueType == Enum.UserSubscribeType.USER_SUBSCRIBE_TYPE_HATCH_EGG then
      newPlayerSettings.userSubscribe.hatch_egg = bIsOpen
    elseif data.UniqueType == Enum.UserSubscribeType.USER_SUBSCRIBE_TYPE_TRAVEL then
      newPlayerSettings.userSubscribe.travel = bIsOpen
    elseif data.UniqueType == Enum.UserSubscribeType.USER_SUBSCRIBE_TYPE_DEBRIS_FULL then
      newPlayerSettings.userSubscribe.debris_full = bIsOpen
    elseif data.UniqueType == Enum.UserSubscribeType.USER_SUBSCRIBE_TYPE_FRIEND_BATTLE then
      newPlayerSettings.userSubscribe.friend_battle = bIsOpen
    elseif data.UniqueType == Enum.UserSubscribeType.USER_SUBSCRIBE_TYPE_NEW_ACTIVITY then
      newPlayerSettings.userSubscribe.new_activity = bIsOpen
    elseif data.UniqueType == Enum.UserSubscribeType.USER_SUBSCRIBE_TYPE_EXCHANGE_EGG then
      newPlayerSettings.userSubscribe.exchange_egg = bIsOpen
    elseif data.UniqueType == Enum.UserSubscribeType.USER_SUBSCRIBE_TYPE_FRIEND_VISIT then
      newPlayerSettings.userSubscribe.friend_visit = bIsOpen
    end
  else
    newPlayerSettings.userSubscribe = {}
    if data.UniqueType == Enum.UserSubscribeType.USER_SUBSCRIBE_TYPE_HATCH_EGG then
      newPlayerSettings.userSubscribe.hatch_egg = bIsOpen
    elseif data.UniqueType == Enum.UserSubscribeType.USER_SUBSCRIBE_TYPE_TRAVEL then
      newPlayerSettings.userSubscribe.travel = bIsOpen
    elseif data.UniqueType == Enum.UserSubscribeType.USER_SUBSCRIBE_TYPE_DEBRIS_FULL then
      newPlayerSettings.userSubscribe.debris_full = bIsOpen
    elseif data.UniqueType == Enum.UserSubscribeType.USER_SUBSCRIBE_TYPE_FRIEND_BATTLE then
      newPlayerSettings.userSubscribe.friend_battle = bIsOpen
    elseif data.UniqueType == Enum.UserSubscribeType.USER_SUBSCRIBE_TYPE_NEW_ACTIVITY then
      newPlayerSettings.userSubscribe.new_activity = bIsOpen
    elseif data.UniqueType == Enum.UserSubscribeType.USER_SUBSCRIBE_TYPE_EXCHANGE_EGG then
      newPlayerSettings.userSubscribe.exchange_egg = bIsOpen
    elseif data.UniqueType == Enum.UserSubscribeType.USER_SUBSCRIBE_TYPE_FRIEND_VISIT then
      newPlayerSettings.userSubscribe.friend_visit = bIsOpen
    end
  end
  if not RocoEnv.PLATFORM_WINDOWS then
    if bIsOpen then
      if UE.UNRCPermissionMgr.IfRequestPermissionSupport(UE.ENRCPermissionType.Notifications) then
        if self._permissionNotificationCheckID then
          UE.UNRCPermissionMgr.CancelIfRequestPermissionGrantedAsync(self._permissionNotificationCheckID)
          self._permissionNotificationCheckID = nil
        end
        self._permissionNotificationCheckID = UE.UNRCPermissionMgr.IfPermissionGrantedAsync(UE.ENRCPermissionType.Notifications, SimpleDelegateFactory:CreateCallback(self, function(_, PermissionStatus)
          Log.Info("UMG_MessageSettingList_C:OnIfNotificationsPermissionGrantedAsyncCallback ", PermissionStatus)
          self._permissionNotificationCheckID = nil
          self._permissionNotificationStatus = PermissionStatus
          if 0 == PermissionStatus then
            Log.Info("UMG_MessageSettingList_C:Notification Permission Already Granted")
            _G.NRCModuleManager:DoCmd(_G.SystemSettingModuleCmd.ReqModifyPlayerSettings, newPlayerSettings)
          else
            self:SetUpNotificationList()
            _G.NRCModuleManager:DoCmd(_G.SystemSettingModuleCmd.OpenCloudMessageManagementPopUp)
          end
        end))
      else
        self:SetUpNotificationList()
        UE.UNRCPermissionMgr.JumpToSysSetting()
      end
    else
      _G.NRCModuleManager:DoCmd(_G.SystemSettingModuleCmd.ReqModifyPlayerSettings, newPlayerSettings)
    end
  end
end

function UMG_SystemSettingMain_C:SetUpNotificationList()
  local notificationList = {}
  local defaultPlayerSettings = _G.NRCModuleManager:DoCmd(_G.SystemSettingModuleCmd.GetPlayerSettings)
  local hideMessageNotification = _G.NRCModuleManager:DoCmd(_G.FunctionBanModuleCmd.CheckUIFunctionBan, _G.Enum.FunctionEntrance.FE_MSG_NOTIFICATION, false)
  if RocoEnv.PLATFORM_WINDOWS then
    hideMessageNotification = true
  end
  if not hideMessageNotification then
    self.NotificationSettings:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
  else
    self.NotificationSettings:SetVisibility(UE4.ESlateVisibility.Collapsed)
  end
  local hideWechatSubscribe = _G.NRCModuleManager:DoCmd(_G.FunctionBanModuleCmd.CheckUIFunctionBan, _G.Enum.FunctionEntrance.FE_MSG_NOTIFICATION_WX_SUB, false)
  if not hideWechatSubscribe then
    table.insert(notificationList, {
      itemTitle = LuaText.setting_image_29,
      bNeedDescribe = true,
      describeText = LuaText.setting_privacy_notice,
      settingBtnText = LuaText.setting_image_72,
      bNeedSettingBtnIcon = true,
      settingBtnHandler = self.OpenUserSubscribeTpl,
      itemType = 2,
      Call = self,
      CloseSelectionBtn = self.HitTestBgBtn,
      CloseAnnotationBtn = self.HitTestBgBtn_1,
      parentList = self.NotificationList
    })
  end
  local hideHatchEgg = _G.NRCModuleManager:DoCmd(_G.FunctionBanModuleCmd.CheckUIFunctionBan, _G.Enum.FunctionEntrance.FE_MSG_NOTIFICATION_HATCH_EGG, false)
  if not hideHatchEgg then
    local notificationSwitchItemList = {}
    local notificationItemListKey = 1
    if defaultPlayerSettings and defaultPlayerSettings.userSubscribe then
      if true == defaultPlayerSettings.userSubscribe.hatch_egg then
        notificationItemListKey = 0
      elseif defaultPlayerSettings.userSubscribe.hatch_egg == false then
        notificationItemListKey = 1
      end
    else
      notificationItemListKey = 1
    end
    local data = {
      Name = LuaText.push_setting_3,
      UniqueType = Enum.UserSubscribeType.USER_SUBSCRIBE_TYPE_HATCH_EGG
    }
    table.insert(notificationSwitchItemList, {
      btnText = LuaText.setting_image_33,
      selectHandler = FPartial(OnUserSubscribeChanged, self, data, true),
      Call = self
    })
    table.insert(notificationSwitchItemList, {
      btnText = LuaText.setting_image_45,
      selectHandler = FPartial(OnUserSubscribeChanged, self, data, false),
      Call = self
    })
    table.insert(notificationList, {
      itemTitle = LuaText.push_setting_3,
      switchBtnListInfo = notificationSwitchItemList,
      switchBtnListKey = notificationItemListKey,
      itemType = 4,
      Call = self,
      CloseSelectionBtn = self.HitTestBgBtn,
      CloseAnnotationBtn = self.HitTestBgBtn_1,
      parentList = self.NotificationList
    })
  end
  local hideTravel = _G.NRCModuleManager:DoCmd(_G.FunctionBanModuleCmd.CheckUIFunctionBan, _G.Enum.FunctionEntrance.FE_MSG_NOTIFICATION_TRAVEL, false)
  if not hideTravel then
    local notificationSwitchItemList1 = {}
    local notificationItemList1Key = 1
    if defaultPlayerSettings and defaultPlayerSettings.userSubscribe then
      if true == defaultPlayerSettings.userSubscribe.travel then
        notificationItemList1Key = 0
      elseif false == defaultPlayerSettings.userSubscribe.travel then
        notificationItemList1Key = 1
      end
    else
      notificationItemList1Key = 1
    end
    local data1 = {
      Name = LuaText.push_setting_4,
      UniqueType = Enum.UserSubscribeType.USER_SUBSCRIBE_TYPE_TRAVEL
    }
    table.insert(notificationSwitchItemList1, {
      btnText = LuaText.setting_image_33,
      selectHandler = FPartial(OnUserSubscribeChanged, self, data1, true),
      Call = self
    })
    table.insert(notificationSwitchItemList1, {
      btnText = LuaText.setting_image_45,
      selectHandler = FPartial(OnUserSubscribeChanged, self, data1, false),
      Call = self
    })
    table.insert(notificationList, {
      itemTitle = LuaText.push_setting_4,
      switchBtnListInfo = notificationSwitchItemList1,
      switchBtnListKey = notificationItemList1Key,
      itemType = 4,
      Call = self,
      CloseSelectionBtn = self.HitTestBgBtn,
      CloseAnnotationBtn = self.HitTestBgBtn_1,
      parentList = self.NotificationList
    })
  end
  local hideDebrisFull = _G.NRCModuleManager:DoCmd(_G.FunctionBanModuleCmd.CheckUIFunctionBan, _G.Enum.FunctionEntrance.FE_MSG_NOTIFICATION_DEBRIS_FULL, false)
  if not hideDebrisFull then
    local notificationSwitchItemList2 = {}
    local notificationItemList2Key = 1
    if defaultPlayerSettings and defaultPlayerSettings.userSubscribe then
      if true == defaultPlayerSettings.userSubscribe.debris_full then
        notificationItemList2Key = 0
      elseif false == defaultPlayerSettings.userSubscribe.debris_full then
        notificationItemList2Key = 1
      end
    else
      notificationItemList2Key = 1
    end
    local data2 = {
      Name = LuaText.push_setting_5,
      UniqueType = Enum.UserSubscribeType.USER_SUBSCRIBE_TYPE_DEBRIS_FULL
    }
    table.insert(notificationSwitchItemList2, {
      btnText = LuaText.setting_image_33,
      selectHandler = FPartial(OnUserSubscribeChanged, self, data2, true),
      Call = self
    })
    table.insert(notificationSwitchItemList2, {
      btnText = LuaText.setting_image_45,
      selectHandler = FPartial(OnUserSubscribeChanged, self, data2, false),
      Call = self
    })
    table.insert(notificationList, {
      itemTitle = LuaText.push_setting_5,
      switchBtnListInfo = notificationSwitchItemList2,
      switchBtnListKey = notificationItemList2Key,
      itemType = 4,
      Call = self,
      CloseSelectionBtn = self.HitTestBgBtn,
      CloseAnnotationBtn = self.HitTestBgBtn_1,
      parentList = self.NotificationList
    })
  end
  local hideFriendBattle = _G.NRCModuleManager:DoCmd(_G.FunctionBanModuleCmd.CheckUIFunctionBan, _G.Enum.FunctionEntrance.FE_MSG_NOTIFICATION_FRIEND_BATTLE, false)
  if not hideFriendBattle then
    local notificationSwitchItemList3 = {}
    local notificationItemList3Key = 1
    if defaultPlayerSettings and defaultPlayerSettings.userSubscribe then
      if true == defaultPlayerSettings.userSubscribe.friend_battle then
        notificationItemList3Key = 0
      elseif false == defaultPlayerSettings.userSubscribe.friend_battle then
        notificationItemList3Key = 1
      end
    else
      notificationItemList3Key = 1
    end
    local data3 = {
      Name = LuaText.push_setting_6,
      UniqueType = Enum.UserSubscribeType.USER_SUBSCRIBE_TYPE_FRIEND_BATTLE
    }
    table.insert(notificationSwitchItemList3, {
      btnText = LuaText.setting_image_33,
      selectHandler = FPartial(OnUserSubscribeChanged, self, data3, true),
      Call = self
    })
    table.insert(notificationSwitchItemList3, {
      btnText = LuaText.setting_image_45,
      selectHandler = FPartial(OnUserSubscribeChanged, self, data3, false),
      Call = self
    })
    table.insert(notificationList, {
      itemTitle = LuaText.push_setting_6,
      switchBtnListInfo = notificationSwitchItemList3,
      switchBtnListKey = notificationItemList3Key,
      itemType = 4,
      Call = self,
      CloseSelectionBtn = self.HitTestBgBtn,
      CloseAnnotationBtn = self.HitTestBgBtn_1,
      parentList = self.NotificationList
    })
  end
  local hideNewActivity = _G.NRCModuleManager:DoCmd(_G.FunctionBanModuleCmd.CheckUIFunctionBan, _G.Enum.FunctionEntrance.FE_MSG_NOTIFICATION_NEW_ACTIVITY, false)
  if not hideNewActivity then
    local notificationSwitchItemList4 = {}
    local notificationItemList4Key = 1
    if defaultPlayerSettings and defaultPlayerSettings.userSubscribe then
      if true == defaultPlayerSettings.userSubscribe.new_activity then
        notificationItemList4Key = 0
      elseif false == defaultPlayerSettings.userSubscribe.new_activity then
        notificationItemList4Key = 1
      end
    else
      notificationItemList4Key = 1
    end
    local data4 = {
      Name = LuaText.push_setting_7,
      UniqueType = Enum.UserSubscribeType.USER_SUBSCRIBE_TYPE_NEW_ACTIVITY
    }
    table.insert(notificationSwitchItemList4, {
      btnText = LuaText.setting_image_33,
      selectHandler = FPartial(OnUserSubscribeChanged, self, data4, true),
      Call = self
    })
    table.insert(notificationSwitchItemList4, {
      btnText = LuaText.setting_image_45,
      selectHandler = FPartial(OnUserSubscribeChanged, self, data4, false),
      Call = self
    })
    table.insert(notificationList, {
      itemTitle = LuaText.push_setting_7,
      switchBtnListInfo = notificationSwitchItemList4,
      switchBtnListKey = notificationItemList4Key,
      itemType = 4,
      Call = self,
      CloseSelectionBtn = self.HitTestBgBtn,
      CloseAnnotationBtn = self.HitTestBgBtn_1,
      parentList = self.NotificationList
    })
  end
  local hideExchangeEgg = _G.NRCModuleManager:DoCmd(_G.FunctionBanModuleCmd.CheckUIFunctionBan, _G.Enum.FunctionEntrance.FE_MSG_NOTIFICATION_EXCHANGE_EGG, false)
  if not hideExchangeEgg then
    local notificationSwitchItemList5 = {}
    local notificationItemList5Key = 1
    if defaultPlayerSettings and defaultPlayerSettings.userSubscribe then
      if true == defaultPlayerSettings.userSubscribe.exchange_egg then
        notificationItemList5Key = 0
      elseif false == defaultPlayerSettings.userSubscribe.exchange_egg then
        notificationItemList5Key = 1
      end
    else
      notificationItemList5Key = 1
    end
    local data5 = {
      Name = LuaText.push_setting_8,
      UniqueType = Enum.UserSubscribeType.USER_SUBSCRIBE_TYPE_EXCHANGE_EGG
    }
    table.insert(notificationSwitchItemList5, {
      btnText = LuaText.setting_image_33,
      selectHandler = FPartial(OnUserSubscribeChanged, self, data5, true),
      Call = self
    })
    table.insert(notificationSwitchItemList5, {
      btnText = LuaText.setting_image_45,
      selectHandler = FPartial(OnUserSubscribeChanged, self, data5, false),
      Call = self
    })
    table.insert(notificationList, {
      itemTitle = LuaText.push_setting_8,
      switchBtnListInfo = notificationSwitchItemList5,
      switchBtnListKey = notificationItemList5Key,
      itemType = 4,
      Call = self,
      CloseSelectionBtn = self.HitTestBgBtn,
      CloseAnnotationBtn = self.HitTestBgBtn_1,
      parentList = self.NotificationList
    })
  end
  local hideFriendVisit = _G.NRCModuleManager:DoCmd(_G.FunctionBanModuleCmd.CheckUIFunctionBan, _G.Enum.FunctionEntrance.FE_MSG_NOTIFICATION_FRIEND_VISIT, false)
  if not hideFriendVisit then
    local notificationSwitchItemList6 = {}
    local notificationItemList6Key = 1
    if defaultPlayerSettings and defaultPlayerSettings.userSubscribe then
      if true == defaultPlayerSettings.userSubscribe.friend_visit then
        notificationItemList6Key = 0
      elseif false == defaultPlayerSettings.userSubscribe.friend_visit then
        notificationItemList6Key = 1
      end
    else
      notificationItemList6Key = 1
    end
    local data6 = {
      Name = LuaText.push_setting_9,
      UniqueType = Enum.UserSubscribeType.USER_SUBSCRIBE_TYPE_FRIEND_VISIT
    }
    table.insert(notificationSwitchItemList6, {
      btnText = LuaText.setting_image_33,
      selectHandler = FPartial(OnUserSubscribeChanged, self, data6, true),
      Call = self
    })
    table.insert(notificationSwitchItemList6, {
      btnText = LuaText.setting_image_45,
      selectHandler = FPartial(OnUserSubscribeChanged, self, data6, false),
      Call = self
    })
    table.insert(notificationList, {
      itemTitle = LuaText.push_setting_9,
      switchBtnListInfo = notificationSwitchItemList6,
      switchBtnListKey = notificationItemList6Key,
      itemType = 4,
      Call = self,
      CloseSelectionBtn = self.HitTestBgBtn,
      CloseAnnotationBtn = self.HitTestBgBtn_1,
      parentList = self.NotificationList
    })
  end
  self.NotificationList:InitGridView(notificationList)
end

function UMG_SystemSettingMain_C:CheckUserSubscribe(userSubscribeType)
  return _G.NRCModuleManager:DoCmd(_G.SystemSettingModuleCmd.CheckUserSubscribeInfo, userSubscribeType)
end

function UMG_SystemSettingMain_C:OnIfNotificationsPermissionGrantedAsyncCallback(PermissionStatus)
  Log.Info("UMG_MessageSettingList_C:OnIfNotificationsPermissionGrantedAsyncCallback ", PermissionStatus)
  self._permissionNotificationCheckID = nil
  self._permissionNotificationStatus = PermissionStatus
  if 0 == PermissionStatus then
    Log.Info("UMG_MessageSettingList_C:Notification Permission Already Granted")
  else
    _G.NRCModuleManager:DoCmd(_G.SystemSettingModuleCmd.OpenCloudMessageManagementPopUp)
  end
end

function UMG_SystemSettingMain_C:SetupDropDownList()
  Log.Debug("UMG_SystemSettingMain_C:SetupDropDownList")
  local ResolutionX, ResolutionY, CanUse = UE4.UNRCQualityLibrary.GetPCResolutionList()
  local Options = {}
  local ResolutionName = {
    [1] = LuaText.setting_image_full_screen,
    [2] = LuaText.setting_image_full_screen,
    [3] = LuaText.setting_image_window
  }
  ResolutionX = ResolutionX:ToTable()
  ResolutionY = ResolutionY:ToTable()
  for i = 2, #ResolutionX do
    local Option = {}
    Option.Name = string.format("%d*%d %s", ResolutionX[i], ResolutionY[i], ResolutionName[i] or ResolutionName[3])
    Option.Value = i - 1
    table.insert(Options, Option)
  end
  local cur_x, cur_y, index = UE4.UNRCQualityLibrary.GetPCResolution()
  local resolutionItem = self:GetModeListItemByDropDownListKey("Resoluction")
  if resolutionItem then
    resolutionItem.DropDownList:SelectItemByKeyDirectly(index)
  end
  if UE4Helper.IsPCMode() then
    Options = {
      {
        Name = LuaText.setting_image_73,
        Value = 0
      },
      {
        Name = LuaText.setting_image_82,
        Value = 1
      }
    }
    local apiSelectValue = UE4.UNRCQualityLibrary.IsPreferD3D12() and 1 or 0
    local APIItem = self:GetModeListItemByDropDownListKey("GraphicsAPI")
    if APIItem then
      APIItem.DropDownList:SelectItemByIndexDirectly(apiSelectValue)
    end
  else
  end
end

function UMG_SystemSettingMain_C:RefreshDropDownList(key, value, extraKey, bIsResetGraphic)
  local Table = self.QualityGroupTable or _G.DataConfigManager:GetTable(DataConfigManager.ConfigTableId.QUALITY_GROUP_SETTING_CONF):GetAllDatas()
  local ImageQualityLevel = UE4.UNRCQualityLibrary.GetImageQuality()
  local UnifiedDeviceLevel = UE4.UNRCQualityLibrary.GetUnifiedDeviceLevel()
  local SelfHitTestInvisible = UE4.ESlateVisibility.SelfHitTestInvisible
  local Collapsed = UE4.ESlateVisibility.Collapsed
  local devLevel = UE4.UNRCQualityLibrary.GetDefaultImageQuality()
  local isBanSwitchBtnListRefresh = true
  if true == bIsResetGraphic then
    isBanSwitchBtnListRefresh = false
    if self.DropDownList then
      for _, dd in ipairs(self.DropDownList) do
        if true == dd.IsOpenMenu then
          dd.IsOpenMenu = false
          dd:SwitchState(false, false)
        end
      end
      self:ShowDropDownListCallback({IsOpenMenu = false})
    end
  end
  local level = UE4.UNRCQualityLibrary.GetFrameQuality()
  local selectIndex = 0
  local config = self.module.data:GetGraphicConfigByKey("FPS")
  local Options = self:CopyCurOptions(config.Options, UE4.UNRCQualityLibrary.GetCurMaxFrameQuality(), SystemSettingEnum.QualityID.FPS)
  local bPC = UE4Helper.IsPCMode()
  for i = #Options, 1, -1 do
    local Option = Options[i]
    if Option.bPC ~= nil and Option.bPC ~= bPC then
      table.remove(Options, i)
    end
  end
  for i, Option in ipairs(Options) do
    if Option.Value == level then
      selectIndex = i - 1
    end
  end
  local FPSItem = self:GetModeListItemByDropDownListKey("FPS")
  if FPSItem then
    FPSItem.DropDownList:SelectItemByIndexDirectly(selectIndex)
  end
  if UnifiedDeviceLevel >= Table[SystemSettingEnum.QualityID.FPS].Qualities[1].RequireUnifiedDeviceLevel and #Options > 1 then
    FPSItem:SetVisibility(SelfHitTestInvisible)
  else
    FPSItem:SetVisibility(Collapsed)
  end
  level = UE4.UNRCQualityLibrary.GetMobileResolutionQuality()
  selectIndex = level
  config = self.module.data:GetGraphicConfigByKey("MobileResolution")
  Options = self:CopyCurOptions(config.Options, UE4.UNRCQualityLibrary.GetCurMaxMobileResolutionQuality(), SystemSettingEnum.QualityID.MobileResolution)
  for i, Option in ipairs(Options) do
    if Option.Value == level then
      selectIndex = i - 1
    end
  end
  local resolutionItem = self:GetModeListItemByDropDownListKey("MobileResolution")
  if resolutionItem then
    resolutionItem.DropDownList:SelectItemByIndexDirectly(selectIndex)
  end
  if not self:IsPCMode() and UnifiedDeviceLevel >= Table[SystemSettingEnum.QualityID.MobileResolution].Qualities[1].RequireUnifiedDeviceLevel and #Options > 1 then
    if resolutionItem then
      resolutionItem:SetVisibility(SelfHitTestInvisible)
    end
  elseif resolutionItem then
    resolutionItem:SetVisibility(Collapsed)
  end
  local settingItemList = {}
  config = self.module.data:GetGraphicConfigByKey("ImageQuality")
  Options = self:CopyCurOptions(config.Options, UE4.UNRCQualityLibrary.GetCurMaxImageQuality(), SystemSettingEnum.QualityID.ImageQuality, UE4.ENRCImageQuality.Custom)
  for _, option in ipairs(Options) do
    if option.Value == devLevel then
      option.Recommend = true
    end
  end
  table.insert(settingItemList, {
    itemTitle = LuaText.setting_image_44,
    itemType = 3,
    Call = self,
    DropDownListInfo = Options,
    DropDownListKey = "ImageQuality",
    DropDownListSelectValue = ImageQualityLevel,
    CloseSelectionBtn = self.HitTestBgBtn,
    CloseAnnotationBtn = self.HitTestBgBtn_1,
    bIsBanRefreshSwitchBtnList = isBanSwitchBtnListRefresh
  })
  local QualityGroups = {}
  local QualityCfg = UE4.UNRCQualityLibrary.GetQualityConfigurations(ImageQualityLevel):ToTable()
  UnifiedDeviceLevel = UE4.UNRCQualityLibrary.GetUnifiedDeviceLevel()
  Table = self.QualityGroupTable or _G.DataConfigManager:GetTable(DataConfigManager.ConfigTableId.QUALITY_GROUP_SETTING_CONF):GetAllDatas()
  for j, _QualityTable in ipairs(Table) do
    if _QualityTable.groupName and _QualityTable.is_effect_quality and _QualityTable.is_effect_quality > 0 then
      local GroupName = _QualityTable.groupName
      if not bPC and "VsyncQuality" == GroupName then
      else
        local RequireUnifiedDeviceLevel = _QualityTable.Qualities[1] and _QualityTable.Qualities[1].RequireUnifiedDeviceLevel or 0
        config = self.module.data:GetGraphicConfigByKey(GroupName)
        if config then
          Options = config.Options
        else
          Options = {
            {
              Name = LuaText.systemsettingmoduledata_4,
              Value = 0
            },
            {
              Name = LuaText.systemsettingmoduledata_5,
              Value = 1
            },
            {
              Name = LuaText.systemsettingmoduledata_6,
              Value = 2
            },
            {
              Name = LuaText.systemsettingmoduledata_16,
              Value = 3
            }
          }
        end
        Options = self:CopyCurOptions(Options, UE4.UNRCQualityLibrary.GetCurMaxImageGroupQualityValue(GroupName), _QualityTable.id)
        if UnifiedDeviceLevel >= RequireUnifiedDeviceLevel and #Options > 1 then
          local QualityGroup = {}
          QualityGroup.caller = self
          QualityGroup.Name = _QualityTable.name
          QualityGroup.GroupName = GroupName
          QualityGroup.Options = Options
          QualityGroup.Annotation = _QualityTable.annotation
          QualityGroup.CloseSelectionBtn = self.HitTestBgBtn
          QualityGroup.CloseAnnotationBtn = self.HitTestBgBtn_1
          if ImageQualityLevel == UE4.ENRCImageQuality.Custom then
            QualityGroup.Level = UE4.UNRCQualityLibrary.GetGroupQualityLevel(GroupName) or 0
          else
            local optionValue = QualityCfg["sg." .. GroupName] or 0
            UE4.UNRCQualityLibrary.SetGroupQualityLevel(GroupName, optionValue)
            QualityGroup.Level = optionValue
          end
          QualityGroup.ShowPriority = _QualityTable.is_effect_quality
          table.insert(QualityGroups, QualityGroup)
        end
      end
    end
  end
  table.sort(QualityGroups, function(a, b)
    return a.ShowPriority < b.ShowPriority
  end)
  for _, qualityItem in ipairs(QualityGroups) do
    if not qualityItem.Level then
      qualityItem.Level = 0
    elseif qualityItem.GroupName == "EffectsQuality" then
      if 2 == qualityItem.Level then
        qualityItem.Level = 1
      end
    elseif qualityItem.GroupName == "ReflectionQuality" then
      qualityItem.Level = qualityItem.Level >= 2 and 2 or 0
    end
    if qualityItem.Name == "\229\143\141\229\176\132\232\180\168\233\135\143" then
      local function OnReflectionItemClicked(key1, value1)
        _G.NRCModuleManager:DoCmd(_G.SystemSettingModuleCmd.ApplyConfig, key1, value1)
      end
      
      local reflectionItemList = {}
      local reflectionItemListKey = self:GetReflectionItemListKey(qualityItem)
      table.insert(reflectionItemList, {
        btnText = LuaText.setting_image_33,
        selectHandler = FPartial(OnReflectionItemClicked, qualityItem.GroupName, qualityItem.Options[2].Value),
        Call = self
      })
      table.insert(reflectionItemList, {
        btnText = LuaText.setting_image_45,
        selectHandler = FPartial(OnReflectionItemClicked, qualityItem.GroupName, qualityItem.Options[1].Value),
        Call = self
      })
      if qualityItem.Annotation then
        table.insert(settingItemList, {
          itemTitle = qualityItem.Name,
          bNeedDescribe = true,
          describeText = qualityItem.Annotation,
          itemType = 4,
          Call = self,
          switchBtnListInfo = reflectionItemList,
          switchBtnListKey = reflectionItemListKey,
          CloseSelectionBtn = qualityItem.CloseSelectionBtn,
          CloseAnnotationBtn = qualityItem.CloseAnnotationBtn,
          bIsBanRefreshSwitchBtnList = isBanSwitchBtnListRefresh
        })
      else
        table.insert(settingItemList, {
          itemTitle = qualityItem.Name,
          itemType = 4,
          Call = self,
          switchBtnListInfo = reflectionItemList,
          switchBtnListKey = reflectionItemListKey,
          CloseSelectionBtn = qualityItem.CloseSelectionBtn,
          CloseAnnotationBtn = qualityItem.CloseAnnotationBtn,
          bIsBanRefreshSwitchBtnList = isBanSwitchBtnListRefresh
        })
      end
    elseif qualityItem.Name == "\230\138\151\233\148\175\233\189\191" then
      local DLSSConfig = JsonUtils.LoadSaved(_DLSSConfigFilename, {}) or {}
      local reflectionItemList = {}
      local reflectionItemListKey = DLSSConfig.AntiAliasing or 0
      local banRefreshSwitchBtnList = isBanSwitchBtnListRefresh
      if "DLSS" == key and "Type" == extraKey then
        if DLSSConfig.Type and 2 == DLSSConfig.Type then
          banRefreshSwitchBtnList = false
        elseif DLSSConfig.Type and 0 == DLSSConfig.Type then
          banRefreshSwitchBtnList = false
        end
      end
      if 1 == reflectionItemListKey and bIsResetGraphic then
        UE4.UNRCStatics.ExecConsoleCommand("r.MobileMSAA 1")
      end
      
      local function OnAntiAliasingQualityItemClicked(bOpen)
        DLSSConfig = JsonUtils.LoadSaved(_DLSSConfigFilename, {}) or {}
        if bOpen then
          local antiAliasLevel = UE4.UNRCQualityLibrary.GetGroupQualityLevel(qualityItem.GroupName)
          UE4.UNRCQualityLibrary.SetImageQuality(UE4.ENRCImageQuality.Custom)
          UE4.UNRCQualityLibrary.SetGroupQualityLevel(qualityItem.GroupName, antiAliasLevel)
          DLSSConfig.AntiAliasing = 0
        else
          UE4.UNRCStatics.ExecConsoleCommand("r.MobileMSAA 1")
          DLSSConfig.AntiAliasing = 1
        end
        JsonUtils.DumpSaved(_DLSSConfigFilename, DLSSConfig)
        self:RefreshDropDownList()
      end
      
      table.insert(reflectionItemList, {
        btnText = LuaText.setting_image_33,
        selectHandler = FPartial(OnAntiAliasingQualityItemClicked, true),
        Call = self
      })
      table.insert(reflectionItemList, {
        btnText = LuaText.setting_image_45,
        selectHandler = FPartial(OnAntiAliasingQualityItemClicked, false),
        Call = self
      })
      table.insert(settingItemList, {
        itemTitle = LuaText.setting_image_46,
        itemType = 4,
        Call = self,
        switchBtnListInfo = reflectionItemList,
        switchBtnListKey = reflectionItemListKey,
        CloseSelectionBtn = qualityItem.CloseSelectionBtn,
        CloseAnnotationBtn = qualityItem.CloseAnnotationBtn,
        bIsBanRefreshSwitchBtnList = banRefreshSwitchBtnList
      })
      if qualityItem.Annotation then
        table.insert(settingItemList, {
          itemTitle = LuaText.setting_image_47,
          bNeedDescribe = true,
          describeText = qualityItem.Annotation,
          itemType = 3,
          Call = self,
          DropDownListInfo = qualityItem.Options,
          DropDownListKey = qualityItem.GroupName,
          DropDownListSelectValue = qualityItem.Level,
          CloseSelectionBtn = qualityItem.CloseSelectionBtn,
          CloseAnnotationBtn = qualityItem.CloseAnnotationBtn,
          bIsBanRefreshSwitchBtnList = isBanSwitchBtnListRefresh
        })
      else
        table.insert(settingItemList, {
          itemTitle = LuaText.setting_image_47,
          itemType = 3,
          Call = self,
          DropDownListInfo = qualityItem.Options,
          DropDownListKey = qualityItem.GroupName,
          DropDownListSelectValue = qualityItem.Level,
          CloseSelectionBtn = qualityItem.CloseSelectionBtn,
          CloseAnnotationBtn = qualityItem.CloseAnnotationBtn,
          bIsBanRefreshSwitchBtnList = isBanSwitchBtnListRefresh
        })
      end
    elseif qualityItem.Annotation then
      table.insert(settingItemList, {
        itemTitle = qualityItem.Name,
        bNeedDescribe = true,
        describeText = qualityItem.Annotation,
        itemType = 3,
        Call = self,
        DropDownListInfo = qualityItem.Options,
        DropDownListKey = qualityItem.GroupName,
        DropDownListSelectValue = qualityItem.Level,
        CloseSelectionBtn = qualityItem.CloseSelectionBtn,
        CloseAnnotationBtn = qualityItem.CloseAnnotationBtn,
        bIsBanRefreshSwitchBtnList = isBanSwitchBtnListRefresh
      })
    else
      table.insert(settingItemList, {
        itemTitle = qualityItem.Name,
        itemType = 3,
        Call = self,
        DropDownListInfo = qualityItem.Options,
        DropDownListKey = qualityItem.GroupName,
        DropDownListSelectValue = qualityItem.Level,
        CloseSelectionBtn = qualityItem.CloseSelectionBtn,
        CloseAnnotationBtn = qualityItem.CloseAnnotationBtn,
        bIsBanRefreshSwitchBtnList = isBanSwitchBtnListRefresh
      })
    end
  end
  self.ImageList:InitGridView(settingItemList)
  for j = 1, self.ImageList:GetItemCount() do
    local item = self.ImageList:GetItemByIndex(j - 1)
    if item.uiData.itemTitle == LuaText.setting_image_47 then
      local DLSSConfig = JsonUtils.LoadSaved(_DLSSConfigFilename, {}) or {}
      local bIsAntiAliasing = DLSSConfig.AntiAliasing or 0
      if 0 == bIsAntiAliasing then
        item:SetDisableGreyState(false)
      elseif 1 == bIsAntiAliasing then
        item:SetDisableGreyState(true)
      end
    end
  end
  self:RefreshJoystickMode(key, value)
  self:RefreshPropPlaceMode(key, value)
  local DeviceLoadPercent = UE4.UNRCQualityLibrary.GetDeviceLoad() / 100
  self.LoadSchedule:SetPercent(DeviceLoadPercent)
  if DeviceLoadPercent < 0.66 then
    self.overload:SetText(LuaText.setting_image_fluency)
    self.overload:SetColorAndOpacity(UE4.UNRCStatics.HexToSlateColor("70c800"))
    self.LoadSchedule:SetFillColorAndOpacity(UE4.UNRCStatics.HexToLinearColor("70c800"))
  else
    self.overload:SetText(LuaText.setting_image_overload)
    self.overload:SetColorAndOpacity(UE4.UNRCStatics.HexToSlateColor("AF3D3EFF"))
    self.LoadSchedule:SetFillColorAndOpacity(UE4.UNRCStatics.HexToLinearColor("AF3D3EFF"))
  end
  if "MobileResolution" == key then
    if self.mobileResolutionTimerId then
      _G.DelayManager:CancelDelayById(self.mobileResolutionTimerId)
    end
    self.mobileResolutionTimerId = _G.DelayManager:DelaySeconds(0.1, function()
      self.mobileResolutionTimerId = nil
      self.InvalidationBox_0:SetCanCache(true)
      Log.Debug("UMG_SystemSettingMain_C SetCanCache true")
    end)
    self.InvalidationBox_0:SetCanCache(false)
    Log.Debug("UMG_SystemSettingMain_C SetCanCache false")
  end
end

function UMG_SystemSettingMain_C:RefreshPropPlaceMode(key, value)
  if "propPlaceMode" == key then
    _G.NRCModuleManager:DoCmd(_G.MainUIModuleCmd.SetPropPlaceMode, 1 == value)
  end
end

function UMG_SystemSettingMain_C:RefreshJoystickMode(key, value)
  if "joystickMode" == key then
    local joystickMode = _G.NRCModuleManager:DoCmd(MainUIModuleCmd.GetMoveJoystickMode)
    if 0 == value then
      if joystickMode then
        _G.NRCModuleManager:DoCmd(_G.MainUIModuleCmd.ChangeMoveJoystickMode, false)
      else
        return
      end
    elseif 1 == value then
      if joystickMode then
        return
      else
        _G.NRCModuleManager:DoCmd(_G.MainUIModuleCmd.ChangeMoveJoystickMode, true)
      end
    end
  end
end

function UMG_SystemSettingMain_C:RefreshSecondaryList()
  local playerLv = _G.DataModelMgr.PlayerDataModel:GetPlayerLevel()
  local limitLevel = _G.DataConfigManager:GetActivityGlobalConfig("secondary_password_unlocks_level_restriction").num
  if playerLv >= limitLevel then
    self.SecondaryPassword:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
    self.DelayId = _G.DelayManager:DelayFrames(1, function()
      local secondaryList = {}
      local secondaryPasswordInfo = _G.NRCModuleManager:DoCmd(_G.SystemSettingModuleCmd.GetSecondaryPasswordInfo)
      if secondaryPasswordInfo then
        local secondarySwitchItemList = {}
        local titleText = ""
        local switchKey = 0
        local timeStamp = secondaryPasswordInfo.status_timestamp
        if secondaryPasswordInfo.status then
          if secondaryPasswordInfo.status == ProtoEnum.SecondaryPasswordStatus.SPS_None or secondaryPasswordInfo.status == ProtoEnum.SecondaryPasswordStatus.SPS_Unset then
            titleText = LuaText.setting_image_55
            switchKey = 1
          elseif secondaryPasswordInfo.status == ProtoEnum.SecondaryPasswordStatus.SPS_Set or secondaryPasswordInfo.status == ProtoEnum.SecondaryPasswordStatus.SPS_Disable or secondaryPasswordInfo.status == ProtoEnum.SecondaryPasswordStatus.SPS_Waiting or secondaryPasswordInfo.status == ProtoEnum.SecondaryPasswordStatus.SPS_Free then
            titleText = LuaText.setting_image_70
            switchKey = 0
          end
        end
        
        local function OnOpenSecondaryPasswordSetClicked()
          _G.NRCModuleManager:DoCmd(_G.SystemSettingModuleCmd.OpenSecondaryPasswordSet)
        end
        
        local function OnCloseSecondaryPasswordSetClicked()
          _G.NRCModuleManager:DoCmd(_G.SystemSettingModuleCmd.OpenSecondaryPasswordCancel)
        end
        
        table.insert(secondarySwitchItemList, {
          btnText = LuaText.setting_image_33,
          selectHandler = OnOpenSecondaryPasswordSetClicked,
          Call = self
        })
        table.insert(secondarySwitchItemList, {
          btnText = LuaText.setting_image_45,
          selectHandler = OnCloseSecondaryPasswordSetClicked,
          Call = self
        })
        table.insert(secondaryList, {
          itemTitle = titleText,
          switchBtnListInfo = secondarySwitchItemList,
          switchBtnListKey = switchKey,
          itemType = 4,
          Call = self,
          CloseSelectionBtn = self.HitTestBgBtn,
          CloseAnnotationBtn = self.HitTestBgBtn_1
        })
        
        local function OnOpenSecondaryPasswordModify()
          _G.NRCModuleManager:DoCmd(_G.SystemSettingModuleCmd.OpenSecondaryPasswordModify)
        end
        
        if secondaryPasswordInfo.status and secondaryPasswordInfo.status == ProtoEnum.SecondaryPasswordStatus.SPS_Set or secondaryPasswordInfo.status == ProtoEnum.SecondaryPasswordStatus.SPS_Disable or secondaryPasswordInfo.status == ProtoEnum.SecondaryPasswordStatus.SPS_Waiting or secondaryPasswordInfo.status == ProtoEnum.SecondaryPasswordStatus.SPS_Free then
          table.insert(secondaryList, {
            itemTitle = LuaText.setting_image_79,
            settingBtnText = LuaText.setting_image_77,
            bNeedSettingBtnIcon = true,
            settingBtnHandler = OnOpenSecondaryPasswordModify,
            itemType = 2,
            Call = self,
            CloseSelectionBtn = self.HitTestBgBtn,
            CloseAnnotationBtn = self.HitTestBgBtn_1
          })
        end
        
        local function OnOpenSecondaryPasswordCancelForceDisable()
          _G.NRCModuleManager:DoCmd(_G.SystemSettingModuleCmd.OpenSecondaryPasswordCancelForceDisable)
        end
        
        if secondaryPasswordInfo.status and secondaryPasswordInfo.status == ProtoEnum.SecondaryPasswordStatus.SPS_Disable then
          table.insert(secondaryList, {
            itemTitle = LuaText.setting_image_85,
            settingBtnText = LuaText.setting_image_86,
            settingBtnHandler = OnOpenSecondaryPasswordCancelForceDisable,
            countDownTimeStamp = timeStamp,
            isSecondaryPasswordCountdown = true,
            itemType = 2,
            Call = self,
            CloseSelectionBtn = self.HitTestBgBtn,
            CloseAnnotationBtn = self.HitTestBgBtn_1
          })
        end
        self.SecondaryList:InitGridView(secondaryList)
      end
    end)
  else
    self.SecondaryPassword:SetVisibility(UE4.ESlateVisibility.Collapsed)
  end
end

function UMG_SystemSettingMain_C:RefreshNotificationList()
end

function UMG_SystemSettingMain_C:OnCloudMessageManagementBtnOKClicked()
  Log.Info("UMG_SystemSettingMain_C:OnCloudMessageManagementBtnOKClicked ", self._permissionNotificationStatus)
  _G.NRCModuleManager:DoCmd(_G.SystemSettingModuleCmd.CloseCloudMessageManagementPopUp)
  if 0 ~= self._permissionNotificationStatus then
    if -1 == self._permissionNotificationStatus then
      if self._permissionNotificationRequestID then
        UE.UNRCPermissionMgr.CancelRequestPermissionCallback(self._permissionNotificationRequestID)
        self._permissionNotificationRequestID = nil
      end
      UE.UNRCPermissionMgr.RequestPermission(UE.ENRCPermissionType.Notifications, SimpleDelegateFactory:CreateCallback(self, self.OnRequestNotificationsPermissionCallback))
    else
      UE.UNRCPermissionMgr.JumpToSysSetting()
    end
  end
  self._permissionNotificationRequestID = nil
  self._permissionNotificationStatus = nil
end

function UMG_SystemSettingMain_C:OnRequestNotificationsPermissionCallback(bGranted)
  Log.Info("UMG_SystemSettingMain_C:OnRequestNotificationsPermissionCallback ", bGranted)
  self._permissionNotificationRequestID = nil
end

function UMG_SystemSettingMain_C:SetupDropDownListSelected()
  local level = UE4.UNRCQualityLibrary.GetImageQuality()
  level = UE4.UNRCQualityLibrary.GetFrameQuality()
  level = UE4.UNRCQualityLibrary.GetMobileResolutionQuality()
  local cur_x, cur_y = UE4.UNRCQualityLibrary.GetPCResolution()
end

function UMG_SystemSettingMain_C:SetFpsItemSelect(CanSelect)
end

function UMG_SystemSettingMain_C:SetMobileResolutionItemSelect(CanSelect)
end

function UMG_SystemSettingMain_C:IsPCMode()
  return _G.UE4Helper.IsPCMode()
end

function UMG_SystemSettingMain_C:OnSelecedTabIndex(index, skipSound)
  if 6 == index then
    Log.Error("\228\184\139\232\189\189\231\174\161\231\144\134\229\176\154\230\156\170\229\188\128\229\143\145\229\174\140\230\175\149\239\188\140\229\133\136\231\149\153\231\169\186")
    return
  end
  if not skipSound then
  end
  self.Switcher:SetActiveWidgetIndex(index - 1)
  for i, tabIcon in ipairs(self.TabIcons) do
    if tabIcon.TabType == index then
      tabIcon:SetSelected(true, skipSound)
      self.SelectIndex = i
    else
      tabIcon:SetSelected(false, skipSound)
    end
  end
  self.FirstSelect = true
  self.UpdateTime = 0
  if 1 == index then
    if self.titleConf and self.titleConf.subtitle then
      self.Title1:SetSubtitle(self.titleConf.subtitle[1].subtitle)
    end
  elseif 2 == index then
    if self.titleConf and self.titleConf.subtitle then
      self.Title1:SetSubtitle(self.titleConf.subtitle[2].subtitle)
    end
  elseif 3 == index then
    if self.titleConf and self.titleConf.subtitle then
      self.Title1:SetSubtitle(self.titleConf.subtitle[3].subtitle)
    end
  elseif 4 == index then
    if self.titleConf and self.titleConf.subtitle then
      self.Title1:SetSubtitle(self.titleConf.subtitle[4].subtitle)
    end
  elseif 5 == index then
    if self.titleConf and self.titleConf.subtitle then
      self.Title1:SetSubtitle(self.titleConf.subtitle[5].subtitle)
    end
  elseif 6 == index then
    if self.titleConf and self.titleConf.subtitle then
      self.Title1:SetSubtitle(self.titleConf.subtitle[6].subtitle)
    end
  elseif 7 == index then
    if self.titleConf and self.titleConf.subtitle then
      self.Title1:SetSubtitle(self.titleConf.subtitle[7].subtitle)
    end
    self:UpdateCustomKeyMappingPage()
  end
  if not skipSound then
    _G.NRCAudioManager:PlaySound2DAuto(1001, "UMG_LevelMain_C:OnSelecedTabIndex")
  end
end

function UMG_SystemSettingMain_C:SetCommonTitle()
  self.titleConf = _G.DataConfigManager:GetTitleConf(self:GetPanelName())
  self.Title1:Set_MainTitle(self.titleConf.title)
  self.Title1:SetBg(self.titleConf.head_icon)
  self.Title1:SetSubtitle(self.titleConf.subtitle[1].subtitle)
end

function UMG_SystemSettingMain_C:OnSetPreConfig(value)
  local qualityCfg = UE4.UNRCQualityLibrary.GetQualityConfigurations(value)
  local configValue = qualityCfg:ToTable()
  local optionValue = configValue["sg.ShadowQuality"]
  UE4.UNRCQualityLibrary.SetGroupQualityLevel("ShadowQuality", optionValue)
  self.shadowDropDownList:SetSelectedValue(optionValue)
  optionValue = configValue["sg.FoliageQuality"]
  self.VegetationDropDownList:SetSelectedValue(optionValue)
  optionValue = configValue["sg.PostProcessQuality"]
  UE4.UNRCQualityLibrary.SetGroupQualityLevel("PostProcessQuality", optionValue)
  self.PostprocessingDropDownList:SetSelectedValue(optionValue)
  optionValue = configValue["sg.TextureQuality"]
  UE4.UNRCQualityLibrary.SetGroupQualityLevel("TextureQuality", optionValue)
  self.TexturequalityDropDownList:SetSelectedValue(optionValue)
  optionValue = configValue["sg.SceneDetailQuality"]
  UE4.UNRCQualityLibrary.SetGroupQualityLevel("SceneDetailQuality", optionValue)
  self.GeometricDetailDropDownList:SetSelectedValue(optionValue)
  optionValue = configValue["sg.EffectsQuality"]
  UE4.UNRCQualityLibrary.SetGroupQualityLevel("EffectsQuality", optionValue)
  self.EffectDropDownList:SetSelectedValue(optionValue)
  optionValue = configValue["sg.ViewDistanceQuality"]
  UE4.UNRCQualityLibrary.SetGroupQualityLevel("ViewDistanceQuality", optionValue)
  self.ViewDistanceQualityDropDownList:SetSelectedValue(optionValue)
  optionValue = configValue["sg.ShadingQuality"]
  UE4.UNRCQualityLibrary.SetGroupQualityLevel("ShadingQuality", optionValue)
  self.ShadingQualityDropDownList:SetSelectedValue(optionValue)
  optionValue = configValue["sg.LightQuality"]
  UE4.UNRCQualityLibrary.SetGroupQualityLevel("LightQuality", optionValue)
  self.LightQualityDropDownList:SetSelectedValue(optionValue)
  optionValue = math.min(configValue["sg.EffectsQuality"], 2)
  UE4.UNRCQualityLibrary.SetGroupQualityLevel("EffectsQuality", optionValue)
  self.EffectsQualityDropDownList:SetSelectedValue(optionValue)
  optionValue = configValue["sg.ReflectionQuality"] > 0 and 2 or 0
  UE4.UNRCQualityLibrary.SetGroupQualityLevel("ReflectionQuality", optionValue)
  self.ReflectionQualityDropDownList:SetSelectedValue(optionValue)
  optionValue = configValue["sg.BloomQuality"]
  UE4.UNRCQualityLibrary.SetGroupQualityLevel("BloomQuality", optionValue)
  self.BloomQualityDropDownList:SetSelectedValue(optionValue)
  optionValue = configValue["sg.AntiAliasingQuality"]
  UE4.UNRCQualityLibrary.SetGroupQualityLevel("AntiAliasingQuality", optionValue)
  self.AntiAliasingQualityDropDownList:SetSelectedValue(optionValue)
end

function UMG_SystemSettingMain_C:OnSetImageQuality()
  local level = UE4.UNRCQualityLibrary.GetImageQuality()
end

function UMG_SystemSettingMain_C:OnSetGroupQualityLevel()
  self:OnSetImageQuality()
end

function UMG_SystemSettingMain_C:OnCloseBtn()
  local ia = UE.UNRCEnhancedInputHelper.GetInputAction("IA_CloseMenu")
  UE.UNRCEnhancedInputHelper.UnBindAction(ia)
  self.btnClose:SetIsEnabled(false)
  UE4.UNRCAudioManager.Get():PlaySound2DAuto(41401014, "UMG_SystemSettingMain_C:OnMainSoundChanged")
  self:StopAllAnimations()
  self:OnClose()
end

function UMG_SystemSettingMain_C:OnAnimationFinished(InAnimation)
  if InAnimation == self.Out then
    _G.NRCEventCenter:DispatchEvent(MainUIModuleEvent.OnMainUISubPanelClosed, false)
  elseif InAnimation == self.In or InAnimation == self.Loop then
    self:PlayAnimation(self.Loop)
  end
  NRCPanelBase.OnAnimationFinished(self, InAnimation)
end

function UMG_SystemSettingMain_C:OnHitTestBgBtn()
  for i = 1, self.ModeList:GetItemCount() do
    local item = self.ModeList:GetItemByIndex(i - 1)
    if 3 == item.uiData.itemType and item.DropDownList.IsOpenMenu then
      item.DropDownList:OnShowBtnClick()
      break
    end
  end
  for i = 1, self.ImageList:GetItemCount() do
    local item = self.ImageList:GetItemByIndex(i - 1)
    if 3 == item.uiData.itemType and item.DropDownList.IsOpenMenu then
      item.DropDownList:OnShowBtnClick()
      break
    end
  end
  for i = 1, self.DLSSList:GetItemCount() do
    local item = self.DLSSList:GetItemByIndex(i - 1)
    if item.uiData and 3 == item.uiData.itemType and item.DropDownList.IsOpenMenu then
      item.DropDownList:OnShowBtnClick()
      break
    end
  end
end

function UMG_SystemSettingMain_C:SwitchAccount()
  local DialogContext = require("NewRoco.Modules.System.TipsModule.DialogContext")
  local Context = DialogContext()
  local ContentText = RocoEnv.PLATFORM_WINDOWS and _G.DataConfigManager:GetLocalizationConf("switch_account_tips_pc").msg or _G.DataConfigManager:GetLocalizationConf("setting_switch_account").msg
  Context:SetTitle(LuaText.umg_systemsettingmain_4):SetContent(ContentText):SetMode(DialogContext.Mode.OK_CANCEL):SetCallbackOkOnly(self, self.BackToLogin):SetCloseOnCancel(true):SetCloseOnOK(true):SetClickAnywhereClose(true):SetButtonText(LuaText.umg_systemsettingmain_5, LuaText.umg_systemsettingmain_6)
  _G.NRCModuleManager:DoCmd(TipsModuleCmd.Dialog_OpenDialog, Context)
end

function UMG_SystemSettingMain_C:BackToLogin()
  NRCModuleManager:DoCmd(LoadingUIModuleCmd.OpenLoadingUI, LuaText.Loading, 1, nil, nil, nil, nil, nil, nil, true)
  UE.ULoginStatics.Logout(LoginEnum.ChannelNames.QQ, "", false)
  UE.ULoginStatics.Logout(LoginEnum.ChannelNames.WeChat, "", false)
  NRCModuleManager:DoCmd(OnlineModuleCmd.Logout)
  UE4.UPushStatics.UnregisterXGPush("XG")
  self:DelaySeconds(1, function()
    if _G.RocoEnv.PLATFORM_ANDROID then
      CommonUtils.SendClientEventToCGSDK("{\"name\":\"game-event-progress\", \"content\":{\"type\":\"logout\"}}")
    end
    _G.AppMain.BackToLogin()
  end)
end

function UMG_SystemSettingMain_C:SetupSoundTab()
  local value = self:GetSoundValue("Backstage_Master_RTPC")
  if self.SoundList:GetItemCount() > 0 then
    local soundItem = self.SoundList:GetItemByIndex(0)
    if soundItem then
      soundItem.Slider:SetValue(value)
      soundItem.Progress:SetPercent(value / 10)
      soundItem.Slider:SetStepSize(1)
      soundItem.Slider:SetMinValue(0)
      soundItem.Slider:SetMaxValue(10)
      self:OnSoundChanged(value, true, soundItem.Slider, soundItem.Text, soundItem.Progress, "Backstage_Master_RTPC", 10)
    end
  end
  value = self:GetSoundValue("Backstage_Music_RTPC")
  if self.SoundList:GetItemCount() > 1 then
    local soundItem = self.SoundList:GetItemByIndex(1)
    if soundItem then
      soundItem.Slider:SetValue(value)
      soundItem.Progress:SetPercent(value / 10)
      soundItem.Slider:SetStepSize(1)
      soundItem.Slider:SetMinValue(0)
      soundItem.Slider:SetMaxValue(10)
      self:OnSoundChanged(value, true, soundItem.Slider, soundItem.Text, soundItem.Progress, "Backstage_Music_RTPC", 10)
    end
  end
  value = self:GetSoundValue("Backstage_SFX_RTPC")
  if self.SoundList:GetItemCount() > 2 then
    local soundItem = self.SoundList:GetItemByIndex(2)
    if soundItem then
      soundItem.Slider:SetValue(value)
      soundItem.Progress:SetPercent(value / 10)
      soundItem.Slider:SetStepSize(1)
      soundItem.Slider:SetMinValue(0)
      soundItem.Slider:SetMaxValue(10)
      self:OnSoundChanged(value, true, soundItem.Slider, soundItem.Text, soundItem.Progress, "Backstage_SFX_RTPC", 10)
    end
  end
  value = self:GetSoundValue("Backstage_Pet_RTPC")
  if self.SoundList:GetItemCount() > 3 then
    local soundItem = self.SoundList:GetItemByIndex(3)
    if soundItem then
      soundItem.Slider:SetValue(value)
      soundItem.Progress:SetPercent(value / 10)
      soundItem.Slider:SetStepSize(1)
      soundItem.Slider:SetMinValue(0)
      soundItem.Slider:SetMaxValue(10)
      self:OnSoundChanged(value, true, soundItem.Slider, soundItem.Text, soundItem.Progress, "Backstage_Pet_RTPC", 10)
    end
  end
  self:InitLight()
end

function UMG_SystemSettingMain_C:InitLight()
  self._PreBrightValue = -1
  local value = UE4.UNRCQualityLibrary.GetSceneColorIntensity()
  self.Brightness.Slider:SetValue(value)
  self.Brightness.Progress:SetPercent((value - 0.2) / 1.6)
  local lightNum, dec = math.modf((value - 0.2) / 1.6 * 100)
  lightNum = lightNum + math.floor(dec + 0.5)
  self.Brightness.Text:SetText(tostring(lightNum) .. "%")
  self.Brightness.Slider:SetStepSize(0.1)
  self.Brightness.Slider:SetMinValue(0.2)
  self.Brightness.Slider:SetMaxValue(1.8)
  self:OnBrightSliderChanged(value, true)
end

function UMG_SystemSettingMain_C:SetLensTab()
  local value = self:GetLensValue("HorizontalLens") or 6
  if self.CameraList:GetItemCount() > 0 then
    local cameraItem = self.CameraList:GetItemByIndex(0)
    if cameraItem then
      cameraItem.Slider:SetValue(value)
      cameraItem.Progress:SetPercent(value / 10)
      cameraItem.Slider:SetStepSize(1)
      cameraItem.Slider:SetMinValue(0)
      cameraItem.Slider:SetMaxValue(10)
      self:OnLensChanged(value, true, cameraItem.Slider, cameraItem.Text, cameraItem.Progress, "HorizontalLens", 10)
    end
  end
  value = self:GetLensValue("VerticalLens") or 6
  if self.CameraList:GetItemCount() > 1 then
    local cameraItem = self.CameraList:GetItemByIndex(1)
    if cameraItem then
      cameraItem.Slider:SetValue(value)
      cameraItem.Progress:SetPercent(value / 10)
      cameraItem.Slider:SetStepSize(1)
      cameraItem.Slider:SetMinValue(0)
      cameraItem.Slider:SetMaxValue(10)
      self:OnLensChanged(value, true, cameraItem.Slider, cameraItem.Text, cameraItem.Progress, "VerticalLens", 10)
    end
  end
  value = self:GetLensValue("HorizontalLensAim") or 6
  if self.CameraList:GetItemCount() > 2 then
    local cameraItem = self.CameraList:GetItemByIndex(2)
    if cameraItem then
      cameraItem.Slider:SetValue(value)
      cameraItem.Progress:SetPercent(value / 10)
      cameraItem.Slider:SetStepSize(1)
      cameraItem.Slider:SetMinValue(0)
      cameraItem.Slider:SetMaxValue(10)
      self:OnLensChanged(value, true, cameraItem.Slider, cameraItem.Text, cameraItem.Progress, "HorizontalLensAim", 10)
    end
  end
  value = self:GetLensValue("VerticalLensAim") or 6
  if self.CameraList:GetItemCount() > 3 then
    local cameraItem = self.CameraList:GetItemByIndex(3)
    if cameraItem then
      cameraItem.Slider:SetValue(value)
      cameraItem.Progress:SetPercent(value / 10)
      cameraItem.Slider:SetStepSize(1)
      cameraItem.Slider:SetMinValue(0)
      cameraItem.Slider:SetMaxValue(10)
      self:OnLensChanged(value, true, cameraItem.Slider, cameraItem.Text, cameraItem.Progress, "VerticalLensAim", 10)
    end
  end
end

function UMG_SystemSettingMain_C:SaveSoundConfig()
  local soundConfig = JsonUtils.LoadSaved(_SoundConfigFilename, {})
  local value = self:GetSoundValue("Backstage_Master_RTPC")
  soundConfig.Backstage_Master_RTPC = value
  local value = self:GetSoundValue("Backstage_Music_RTPC")
  soundConfig.Backstage_Music_RTPC = value
  local value = self:GetSoundValue("Backstage_SFX_RTPC")
  soundConfig.Backstage_SFX_RTPC = value
  local value = self:GetSoundValue("Backstage_Pet_RTPC")
  soundConfig.Backstage_Pet_RTPC = value
  for i = 1, self.CameraList:GetItemCount() do
    local item = self.CameraList:GetItemByIndex(i - 1)
    local curValue = item.Slider:GetValue()
    curValue = math.floor(curValue + 0.5)
    if 1 == i then
      soundConfig.HorizontalLens = curValue
    elseif 2 == i then
      soundConfig.VerticalLens = curValue
    elseif 3 == i then
      soundConfig.HorizontalLensAim = curValue
    elseif 4 == i then
      soundConfig.VerticalLensAim = curValue
    end
  end
  JsonUtils.DumpSaved(_SoundConfigFilename, soundConfig)
end

function UMG_SystemSettingMain_C:SetSoundValue(soundName, value)
  _G.NRCAudioManager:SetGlobalRTPC(soundName, value, 0, "UMG_SystemSettingMain_C:SetSoundValue")
end

function UMG_SystemSettingMain_C:GetSoundValue(soundName, value)
  return _G.NRCAudioManager:GetGlobalRTPC(soundName, "UMG_SystemSettingMain_C:GetSoundValue")
end

function UMG_SystemSettingMain_C:SetLensValue(LensName, value)
  _G.UserSettingManager:ChangeCameraRotateSetting(LensName, value)
  local localPlayer = _G.NRCModuleManager:DoCmd(_G.PlayerModuleCmd.GET_LOCAL_PLAYER)
  if localPlayer then
    localPlayer:GetUEController().PlayerCameraManager:RefreshPCCameraRotateSetting()
  end
end

function UMG_SystemSettingMain_C:GetLensValue(LensName)
  local soundConfig = JsonUtils.LoadSaved(_SoundConfigFilename, {})
  local value = soundConfig[LensName]
  return value
end

function UMG_SystemSettingMain_C:OnHorizontalLensChanged(value, slider, text, progressBar)
  self:OnLensChanged(value, false, slider, text, progressBar, "HorizontalLens", 10)
end

function UMG_SystemSettingMain_C:OnVerticalLensChanged(value, slider, text, progressBar)
  self:OnLensChanged(value, false, slider, text, progressBar, "VerticalLens", 10)
end

function UMG_SystemSettingMain_C:OnHorizontalLensAimChanged(value, slider, text, progressBar)
  self:OnLensChanged(value, false, slider, text, progressBar, "HorizontalLensAim", 10)
end

function UMG_SystemSettingMain_C:OnVerticalLensAimChanged(value, slider, text, progressBar)
  self:OnLensChanged(value, false, slider, text, progressBar, "VerticalLensAim", 10)
end

function UMG_SystemSettingMain_C:OnLensChanged(value, skip, Slider, Text, Progress, Name, Max)
  if Slider then
    local curValue = Slider:GetValue()
    curValue = math.floor(curValue + 0.5)
    if Slider then
      Slider:SetValue(curValue)
    end
    if Text then
      Text:SetText(curValue)
    end
    if Progress then
      Progress:SetPercent(curValue / Max)
    end
    if not skip then
      self:SetLensValue(Name, curValue)
      UE4.UNRCAudioManager.Get():PlaySound2DAuto(40007002, "UMG_SystemSettingMain_C:OnMainSoundChanged")
    end
  end
end

function UMG_SystemSettingMain_C:OnMainSoundChanged(value, slider, text, progressBar)
  self:OnSoundChanged(value, false, slider, text, progressBar, "Backstage_Master_RTPC", 10)
end

function UMG_SystemSettingMain_C:OnMusicSoundChanged(value, slider, text, progressBar)
  self:OnSoundChanged(value, false, slider, text, progressBar, "Backstage_Music_RTPC", 10)
end

function UMG_SystemSettingMain_C:OnEffectSoundChanged(value, slider, text, progressBar)
  self:OnSoundChanged(value, false, slider, text, progressBar, "Backstage_SFX_RTPC", 10)
end

function UMG_SystemSettingMain_C:OnYellSoundChanged(value, slider, text, progressBar)
  self:OnSoundChanged(value, false, slider, text, progressBar, "Backstage_Pet_RTPC", 10)
end

local _PreMainSoundValue = -1
local _PreMusicSoundValue = -1
local _PreEffectSoundValue = -1
local _PreYellSoundValue = -1

function UMG_SystemSettingMain_C:OnSoundChanged(value, skip, Slider, Text, Progress, Name, Max)
  if Slider then
    local curValue
    if value then
      curValue = value
    else
      curValue = Slider:GetValue()
    end
    curValue = math.floor(curValue + 0.5)
    if Slider then
      Slider:SetValue(curValue)
    end
    if Text then
      Text:SetText(curValue)
    end
    if Progress then
      Progress:SetPercent(curValue / Max)
    end
    local isChanged
    if "Backstage_Master_RTPC" == Name then
      isChanged = _PreMainSoundValue ~= curValue
      _PreMainSoundValue = curValue
    elseif "Backstage_Music_RTPC" == Name then
      isChanged = _PreMusicSoundValue ~= curValue
      _PreMusicSoundValue = curValue
    elseif "Backstage_SFX_RTPC" == Name then
      isChanged = _PreEffectSoundValue ~= curValue
      _PreEffectSoundValue = curValue
    elseif "Backstage_Pet_RTPC" == Name then
      isChanged = _PreYellSoundValue ~= curValue
      _PreYellSoundValue = curValue
    end
    if not isChanged then
      return
    end
    if not skip then
      self:SetSoundValue(Name, curValue)
      _G.NRCAudioManager:PlaySound2DAuto(40007002, "UMG_SystemSettingMain_C:OnSoundChanged")
    end
  end
end

function UMG_SystemSettingMain_C:OnBrightSliderChanged(value, skip)
  local curValue = self.Brightness.Slider:GetValue()
  local numRounded = math.floor(curValue * 10 + 0.5) / 10
  local isChanged = self._PreBrightValue ~= curValue
  self._PreBrightValue = curValue
  if not isChanged then
    return
  end
  local scale = curValue / 1.6 * 1.2 + 0.2
  self.Brightness.Progress:SetPercent((curValue - 0.2) / 1.6)
  local lightNum, dec = math.modf((curValue - 0.2) / 1.6 * 100)
  lightNum = lightNum + math.floor(dec + 0.5)
  local text = self.Brightness.Text:GetText()
  if not skip then
    UE4.UNRCQualityLibrary.SetSceneColorIntensity(curValue)
    if text ~= tostring(lightNum) .. "%" then
      _G.NRCAudioManager:PlaySound2DAuto(40007002, "UMG_SystemSettingMain_C:OnYellSoundChanged")
    end
  end
  self.Brightness.Text:SetText(tostring(lightNum) .. "%")
  self:SetPreViewBrightness(scale)
end

function UMG_SystemSettingMain_C:SetPreViewBrightness(scale)
  local material = self.LightImage:GetDynamicMaterial()
  if material then
    material:SetScalarParameterValue("Brightness", scale)
  end
  local material1 = self.DarkImage:GetDynamicMaterial()
  if material1 then
    material1:SetScalarParameterValue("Brightness", scale)
  end
end

function UMG_SystemSettingMain_C:OnBrightSliderEnd()
  local ParamSet = {}
  ParamSet.QualityId = -1
  ParamSet.QualityName = LuaText.setting_image_37
  ParamSet.QualityLevel = tonumber(string.match(self.Brightness.Text:GetText(), "%d+"))
  _G.GEMPostManager:SendOptionChangeTLog(ParamSet)
end

function UMG_SystemSettingMain_C:ShowDropDownListCallback(selectedDD)
  if selectedDD.IsOpenMenu == true then
    for _, dd in ipairs(self.DropDownList) do
      if dd ~= selectedDD then
        dd:SetVisibility(UE4.ESlateVisibility.HitTestInvisible)
      end
    end
    _G.NRCEventCenter:DispatchEvent(SystemSettingModuleEvent.OpenSelectionMenu, selectedDD)
    self.HitTestBgBtn:SetVisibility(UE4.ESlateVisibility.Visible)
    self.HitTestBgBtn_2:SetVisibility(UE4.ESlateVisibility.Visible)
    self.HitTestBgBtn_3:SetVisibility(UE4.ESlateVisibility.Visible)
    self.ScrollBox:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
    self.ScrollBox:SetConsumeMouseWheel(UE4.EConsumeMouseWheel.Never)
  else
    for _, dd in ipairs(self.DropDownList) do
      dd:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
    end
    _G.NRCEventCenter:DispatchEvent(SystemSettingModuleEvent.OpenSelectionMenu)
    self.HitTestBgBtn:SetVisibility(UE4.ESlateVisibility.Collapsed)
    self.HitTestBgBtn_2:SetVisibility(UE4.ESlateVisibility.Collapsed)
    self.HitTestBgBtn_3:SetVisibility(UE4.ESlateVisibility.Collapsed)
    self.ScrollBox:SetVisibility(UE4.ESlateVisibility.Visible)
    self.ScrollBox:SetConsumeMouseWheel(UE4.EConsumeMouseWheel.WhenScrollingPossible)
  end
end

function UMG_SystemSettingMain_C:DisableClick()
  self.CanvasPanel_30:SetVisibility(UE4.ESlateVisibility.HitTestInvisible)
  self:DelaySeconds(1.5, function()
    self.CanvasPanel_30:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
  end)
end

function UMG_SystemSettingMain_C:OnOutOfStuckBtnClick()
  local Ctx = DialogContext()
  local tips = LuaText.player_unstuck_confirm
  Ctx:SetContent(tips)
  Ctx:SetMode(DialogContext.Mode.OK_CANCEL)
  Ctx:SetTitle(LuaText.player_unstuck_confirm_title)
  Ctx:SetButtonText(_G.LuaText.tips_dialog_butten_accept, _G.LuaText.tips_dialog_butten_cancel)
  Ctx:SetClickAnywhereClose(true)
  Ctx:SetCloseFlagWhenPlayerDie()
  Ctx:SetCallbackOkOnly(self, self.SendOutOfStuckReq)
  NRCModuleManager:DoCmd(TipsModuleCmd.Dialog_OpenDialog, Ctx)
end

function UMG_SystemSettingMain_C:SendOutOfStuckReq()
  if not self.inInCreatePlayerLevel then
    local req = ProtoMessage:newZoneSceneUnstuckTeleportReq()
    _G.ZoneServer:SendWithHandler(_G.ProtoCMD.ZoneSvrCmd.ZONE_SCENE_UNSTUCK_TELEPORT_REQ, req, self, self.OutOfStuckRsp)
  else
    if CreatePlayerModuleCmd then
      NRCModuleManager:DoCmd(CreatePlayerModuleCmd.TeleportToBirthplace)
    end
    self:DelaySeconds(0.5, function()
      self:OnClose()
    end)
  end
end

function UMG_SystemSettingMain_C:OutOfStuckRsp(rsp)
  if 0 ~= rsp.ret_info.ret_code then
    return
  end
  local CD = rsp.cooldown
  if CD and 0 ~= CD then
    if CD > 60 then
      local minute = CD // 60
      local seconds = CD - minute * 60
      _G.NRCModuleManager:DoCmd(TipsModuleCmd.TopHud_ShowTips, string.format(_G.LuaText.player_unstuck_cooldown_tips, minute, seconds))
    else
      _G.NRCModuleManager:DoCmd(TipsModuleCmd.TopHud_ShowTips, string.format(_G.LuaText.player_unstuck_cooldown_tips2, CD))
    end
  else
    _G.NRCModuleManager:DoCmd(_G.SystemSettingModuleCmd.CloseMainPanel)
  end
end

function UMG_SystemSettingMain_C:OnDataRestorationClick()
  local Ctx = DialogContext()
  local tips = LuaText.taskdata_repair_text
  Ctx:SetContent(tips)
  Ctx:SetMode(DialogContext.Mode.OK_CANCEL)
  Ctx:SetTitle(LuaText.taskdata_repair_title)
  Ctx:SetButtonText(_G.LuaText.taskdata_repair_confirm, _G.LuaText.taskdata_repair_cancel)
  Ctx:SetClickAnywhereClose(true)
  Ctx:SetCloseFlagWhenPlayerDie()
  Ctx:SetCallbackOkOnly(self, self.SendDataRestorationReq)
  NRCModuleManager:DoCmd(TipsModuleCmd.Dialog_OpenDialog, Ctx)
end

function UMG_SystemSettingMain_C:SendDataRestorationReq()
  local NPCModule = _G.NRCModuleManager:GetModule("NPCModule")
  if NPCModule and _G.ZoneServer:IsEnteredCell() then
    NPCModule:QueryPosForServer(self, self.OnQueryPosForServer)
  end
end

function UMG_SystemSettingMain_C:OnQueryPosForServer(Result)
  local Locations = {}
  if Result and Result.bSuccess then
    Locations = Result.ResultLocations:ToTable()
  end
  local Req = ProtoMessage:newZoneSetTaskRecoverAllReq()
  if Locations and #Locations > 0 then
    for _, v in ipairs(Locations) do
      local absPos = SceneUtils.ConvertRelativeToAbsolute(v)
      local svrPos = SceneUtils.ClientPos2ServerPos(absPos)
      table.insert(Req.bonus_relocate_positions, svrPos)
    end
  end
  Log.Debug("UMG_SystemSettingMain_C:OnQueryPosForServer", Result.bSuccess, #Req.bonus_relocate_positions)
  _G.ZoneServer:SendWithHandler(_G.ProtoCMD.ZoneSvrCmd.ZONE_SET_TASK_RECOVER_ALL_REQ, Req, self, self.OnDataRestorationRsp, true, true)
end

function UMG_SystemSettingMain_C:OnDataRestorationRsp(rsp)
  if 0 ~= rsp.ret_info.ret_code then
    Log.Error("\230\149\176\230\141\174\228\191\174\229\164\141\229\164\177\232\180\165", rsp.ret_info.ret_code)
    if rsp.ret_info.ret_code == ProtoEnum.MOBA_RET.ZoneErr.ERR_ZONE_TASK_RECOVER_ALL_IN_CD then
      local Key = string.format("Error_Code_%d", rsp.ret_info.ret_code)
      local ErrorText = _G.DataConfigManager:GetLocalizationConf(Key, true)
      ErrorText = ErrorText and ErrorText.msg
      _G.NRCModuleManager:DoCmd(TipsModuleCmd.TopHud_ShowTips, ErrorText)
    else
      _G.NRCModuleManager:DoCmd(TipsModuleCmd.TopHud_ShowTips, LuaText.taskdata_repair_failed)
    end
    return
  end
  self:BackToLogin()
end

function UMG_SystemSettingMain_C:CopyCurOptions(Options, MaxValue, QualityID, IgnoreType)
  local Table = {}
  local UnifiedDeviceLevel = UE4.UNRCQualityLibrary.GetUnifiedDeviceLevel()
  for index, option in ipairs(Options or {}) do
    local Value = option.Value
    if not MaxValue or MaxValue >= Value or Value == IgnoreType then
      if QualityID and not self:IsPCMode() then
        local RequireUnifiedDeviceLevel = 0
        for i, v in ipairs(self.QualityGroupTable[QualityID].Qualities or {}) do
          if v.Level == Value then
            RequireUnifiedDeviceLevel = v.RequireUnifiedDeviceLevel
            break
          end
        end
        if UnifiedDeviceLevel >= RequireUnifiedDeviceLevel then
          option.QualityID = QualityID
          table.insert(Table, option)
        end
      else
        table.insert(Table, option)
      end
    end
  end
  return Table
end

function UMG_SystemSettingMain_C:CheckIsCreatePlayerLevel()
  local CurWorld = UE4Helper.GetCurrentWorld()
  if CurWorld then
    local GameMode = UE4.UGameplayStatics.GetGameMode(CurWorld)
    local ModeName = GameMode and GameMode:GetName() or ""
    Log.Debug("UMG_SystemSettingMain_C:CheckIsCreatePlayerLevel", ModeName)
    if "" ~= ModeName and string.match(ModeName, "BP_NRCCreatePlayerMode") then
      self.inInCreatePlayerLevel = true
      return
    end
  end
  self.inInCreatePlayerLevel = false
end

function UMG_SystemSettingMain_C:OnCDKEYClick()
  _G.NRCAudioManager:PlaySound2DAuto(1064, "UMG_SystemSettingMain_C:OnCDKEYClick")
  self:DelaySeconds(0.2, function()
    local OnlineModule = _G.NRCModuleManager:GetModule("OnlineModule")
    if not OnlineModule then
      return
    end
    local Data = OnlineModule.data
    local areaId = Data.port
    local url = "https://rocom.qq.com/act/a20241224cdk/index.html?"
    url = url .. "&areaId=" .. areaId
    local screen_type = 1
    local extraJson = "{\"isEmbedWebView\":true}"
    if RocoEnv.PLATFORM == "PLATFORM_OPENHARMONY" then
      screen_type = 3
    elseif RocoEnv.PLATFORM_ANDROID or RocoEnv.PLATFORM_IOS then
      screen_type = 3
    end
    UE4.UWebViewStatics.OpenURL(url, screen_type, false, true, extraJson, false)
  end)
end

function UMG_SystemSettingMain_C:OnBindPhone()
  if self.IsGetBindPhoneInfo then
    return
  end
  self.IsGetBindPhoneInfo = true
  _G.NRCAudioManager:PlaySound2DAuto(1003, "UMG_SystemSettingMain_C:OnBindPhone")
  _G.NRCModuleManager:DoCmd(_G.SystemSettingModuleCmd.ReqGetMobileBindInfo)
end

function UMG_SystemSettingMain_C:OnOpenMapModeSelection()
  _G.NRCAudioManager:PlaySound2DAuto(40008005, "UMG_SystemSettingMain_C:OnOpenMapModeSelection")
  _G.NRCModuleManager:DoCmd(DialogueModuleCmd.OpenMapModeSelection)
end

function UMG_SystemSettingMain_C:ShowBindPhoneText(isHide)
  if not isHide and self.PersonalList then
    local data
    local phoneInfo = _G.DataModelMgr.PlayerDataModel:GetPlayerMobileBindInfo()
    if phoneInfo and phoneInfo.mobile_num and phoneInfo.mobile_num ~= "" then
      data = {
        settingBtnText = LuaText.setting_image_69,
        itemName = self.module.data:GetEncryptPhoneNum(phoneInfo.mobile_num)
      }
    else
      data = {
        settingBtnText = LuaText.setting_image_81,
        itemName = LuaText.Setting_UnBound_Phone_Tips
      }
    end
    for i = 1, self.PersonalList:GetItemCount() do
      local item = self.PersonalList:GetItemByIndex(i - 1)
      if item.uiData.itemTitle == LuaText.setting_image_21 then
        item:UpdatePhoneArea(data)
        break
      end
    end
  end
end

function UMG_SystemSettingMain_C:IsHasNrcCreatePlayerMode()
  if _G.NRCModeManager:GetMode("NRCCreatePlayerMode") then
    return true
  end
end

function UMG_SystemSettingMain_C:OnClickResetCustomKeyMapping()
  if not CommonPopUpModuleCmd then
    return
  end
  local CommonPopUpData = _G.NRCCommonPopUpData()
  CommonPopUpData.RemindSwitch = 0
  CommonPopUpData.ContentText = LuaText.button_setting_reset_tips
  CommonPopUpData.TitleText = LuaText.button_setting_pop_title3
  CommonPopUpData.Btn_LeftText = LuaText.CANCEL
  CommonPopUpData.Btn_RightText = LuaText.umg_bag_popup_2
  CommonPopUpData.Call = self
  CommonPopUpData.Btn_RightHandler = self.OnOk
  _G.NRCModeManager:DoCmd(CommonPopUpModuleCmd.OpenRemindPanel, CommonPopUpData)
end

function UMG_SystemSettingMain_C:OnOk()
  _G.NRCModuleManager:DoCmd(SystemSettingModuleCmd.FullyApplyUserCustomKeyMapping, true)
end

function UMG_SystemSettingMain_C:OnDetailTipsShowNotify()
  self.HitTestBgBtn_1:SetVisibility(UE4.ESlateVisibility.Visible)
end

function UMG_SystemSettingMain_C:UpdateCustomKeyMappingPage(specificButtonType, specificItemIndex, resetMakeSenseButtonSettingIds)
  local tabIconItem = self.TabIcons[self.SelectIndex]
  if 7 ~= tabIconItem.TabType then
    return
  end
  
  local function InitButtonSettingList(listWidget, buttonType)
    local allThisTypeButtonSettingConf = self.module.data.ButtonTypeToButtonSettingConf[buttonType]
    if nil == allThisTypeButtonSettingConf or nil == listWidget then
      return
    end
    listWidget:InitGridView(allThisTypeButtonSettingConf)
  end
  
  if nil == specificItemIndex then
    if nil == specificButtonType then
      for buttonType, listWidget in pairs(self.ButtonTypeToListWidget) do
        InitButtonSettingList(listWidget, buttonType - 1)
      end
    else
      InitButtonSettingList(self.ButtonTypeToListWidget[specificButtonType + 1], specificButtonType)
    end
  elseif specificItemIndex and specificButtonType then
    local listWidget = self.ButtonTypeToListWidget[specificButtonType + 1]
    if nil == listWidget then
      return
    end
    local itemWidget = listWidget:GetItemByIndex(specificItemIndex - 1)
    if itemWidget and itemWidget.UpdateUI then
      itemWidget:UpdateUI()
    end
  end
  if resetMakeSenseButtonSettingIds then
    self:PlayResetAnim(resetMakeSenseButtonSettingIds)
  end
end

function UMG_SystemSettingMain_C:OnClickButtonSettingListItem(buttonSettingConf, itemIndex)
  _G.NRCModuleManager:DoCmd(_G.SystemSettingModuleCmd.OpenKeyStrokeDetectPanel, SystemSettingEnum.KeyStrokeActMode.WaitingInput, buttonSettingConf, itemIndex)
end

function UMG_SystemSettingMain_C:OnCustomClicked()
  _G.NRCAudioManager:PlaySound2DAuto(1011, "UMG_SystemSettingMain_C:OnCustomClicked")
  self:DelaySeconds(0.2, function()
    _G.NRCSDKManager:CustomerService(2)
  end)
end

function UMG_SystemSettingMain_C:OnInformationManagementBtnClicked()
  Log.Info("UMG_SystemSettingMain_C:OnInformationManagementBtnClicked")
  _G.NRCModuleManager:DoCmd(_G.SystemSettingModuleCmd.OpenPersonalInformationManagement)
end

function UMG_SystemSettingMain_C:PlayResetAnim(resetMakeSenseButtonSettingIds)
  for buttonType, listWidget in pairs(self.ButtonTypeToListWidget) do
    if listWidget then
      for i = 1, listWidget:GetItemCount() do
        local item = listWidget:GetItemByIndex(i - 1)
        if item and item.PlayResetAnim and item.GetButtonSettingId and resetMakeSenseButtonSettingIds[item:GetButtonSettingId()] then
          item:PlayResetAnim()
        end
      end
    end
  end
end

function UMG_SystemSettingMain_C:OnClickResetGraphic()
  local Ctx = DialogContext()
  Ctx:SetContent(LuaText.setting_image_options_reset_text)
  Ctx:SetMode(DialogContext.Mode.OK_CANCEL)
  Ctx:SetTitle(LuaText.setting_image_options_reset_text_title)
  Ctx:SetButtonText(LuaText.tips_dialog_butten_accept, LuaText.tips_dialog_butten_cancel)
  Ctx:SetCloseFlagWhenPlayerDie()
  Ctx:SetCallbackOkOnly(self, function(UMG_SystemSettingMain)
    UE4.UNRCQualityLibrary.ResetAllToDefault()
    local DLSSConfig = JsonUtils.LoadSaved(_DLSSConfigFilename, {}) or {}
    DLSSConfig.Type = 0
    DLSSConfig.Graphic = 1
    DLSSConfig.FrameGenerate = 0
    DLSSConfig.AntiAliasing = 0
    JsonUtils.DumpSaved(_DLSSConfigFilename, DLSSConfig)
    _G.NRCModuleManager:DoCmd(_G.SystemSettingModuleCmd.ApplyDLSSSettings)
    _G.NRCModuleManager:DoCmd(_G.SystemSettingModuleCmd.ApplyFrameGenerateSettings, DLSSConfig.FrameGenerate)
    UMG_SystemSettingMain:InitLight()
    UMG_SystemSettingMain:SetupDropDownList()
    UMG_SystemSettingMain:RefreshDropDownList(nil, nil, nil, true)
    UMG_SystemSettingMain:RefreshSecondaryList()
  end)
  NRCModuleManager:DoCmd(TipsModuleCmd.Dialog_OpenDialog, Ctx)
end

function UMG_SystemSettingMain_C:OnClickFamilyGuardGotoBtn(privacyOption)
  local url = RocoEnv.IS_SHIPPING and _G.AppMain:GetFormalPipeline() and privacyOption.url_pub or privacyOption.url_dev
  local url_after_encoded = UE4.UWebViewStatics.GetEncodeURL(url)
  Log.Info("UMG_SystemSettingMain_C:OnClickFamilyGuardGotoBtn ", url, url_after_encoded)
  local screenType = 2
  if RocoEnv.PLATFORM == "PLATFORM_WINDOWS" then
    screenType = 1
  end
  local isFullScreen = false
  local isUseURLEncode = true
  local entraJson = ""
  local bIsBrowser = false
  UE4.UWebViewStatics.OpenURL(url, screenType, isFullScreen, isUseURLEncode, entraJson, bIsBrowser)
end

function UMG_SystemSettingMain_C:OnInformationTextClick(url_key)
  self:Log("UMG_SystemSettingMain_C.OnInformationTextClick", url_key)
  for _, v in pairs(self.PrivacyOptions) do
    if v and v.key == url_key and v.func then
      v.func(self, v)
    end
  end
end

function UMG_SystemSettingMain_C:OnPromptTextClick(url_key)
  local url = _G.DataConfigManager:GetGlobalConfigStrByKeyType("privacy_protect_platform", _G.DataConfigManager.ConfigTableId.GLOBAL_CONFIG, "")
  self:Log("UMG_SystemSettingMain_C:OnPromptTextClick", url)
  local screenType = 2
  if RocoEnv.PLATFORM == "PLATFORM_WINDOWS" then
    screenType = 1
  end
  local isFullScreen = false
  local isUseURLEncode = false
  local entraJson = ""
  local bIsBrowser = false
  UE4.UWebViewStatics.OpenURL(url, screenType, isFullScreen, isUseURLEncode, entraJson, bIsBrowser)
end

function UMG_SystemSettingMain_C:ScrollToItemOnDetailTipsShow(itemIndex, parentList)
  if 1 == self.SelectIndex then
    local item = self.ImageList:GetItemByIndex(itemIndex - 1)
    if item then
      self.ScrollBox:ScrollWidgetIntoView(item)
    end
  elseif 5 == self.SelectIndex and parentList then
    local item = parentList:GetItemByIndex(itemIndex - 1)
    if item then
      self.ScrollBox1:ScrollWidgetIntoView(item)
    end
  end
end

function UMG_SystemSettingMain_C:ShowBindPhoneArea(isRspSuccess)
  self.IsRepBindPhone = true
  self:ShowBindPhoneText(not isRspSuccess)
end

function UMG_SystemSettingMain_C:UnLockGetBindPhoneInfo()
  self.IsGetBindPhoneInfo = false
end

return UMG_SystemSettingMain_C

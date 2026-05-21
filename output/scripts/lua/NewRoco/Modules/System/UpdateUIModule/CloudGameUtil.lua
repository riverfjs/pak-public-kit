local rapidjson = require("rapidjson")
local DialogContext = require("NewRoco.Modules.System.TipsModule.DialogContext")
local LoginEnum = require("NewRoco.Modes.LoginMode.LoginEnum")
local UpdateUIModuleEvent = require("NewRoco.Modules.System.UpdateUIModule.UpdateUIModuleEvent")
local LoginUtils = require("NewRoco.Modules.System.LoginModule.LoginUtils")
local LoginModuleEvent = reload("NewRoco.Modules.System.LoginModule.LoginModuleEvent")
local DEFAULT_ENCRYPTION_KEY = "cG(.^TNRC9hY,DkX?KX%w)p(^Yo>}n}`"
local CloudGamePackageName = "com.tencent.gamematrix.nrc"
local CloudGameConfigName = "CloudGameConfig"
local CloudGameConfigURL = "https://config.nrc.qq.com/config/" .. CloudGameConfigName
local OfficialChannel = 89900051
local OfficialChannelUrl = "https://rocom.qq.com"
local LiteGameVersion
local PermissionUrl = "https://m.gamer.qq.com/v2/help/application?iGameID=97924"
local PrivacyUrl = "https://gamematrixmc.qq.com/d1qeagknurrjseap2s10/0/policy/privacy"
local PopupUrlData = {permissionUrl = PermissionUrl, privacyUrl = PrivacyUrl}
local CloudGameUtil = {
  DEFAULT_ENCRYPTION_KEY = DEFAULT_ENCRYPTION_KEY,
  CloudGamePackageName = CloudGamePackageName,
  CloudGameConfigName = CloudGameConfigName,
  CloudGameJumpUrl = nil,
  PopupUrlData = PopupUrlData,
  LiteGameVersion = nil
}

function CloudGameUtil:DownloadCloudGameConfig()
  if not RocoEnv.PLATFORM_ANDROID then
    return
  end
  Log.Debug("[CloudGameUtil:DownloadCloudGameConfig]")
  self.bGetCloudGameConfigResult = false
  local GameInstance = UE4.UNRCPlatformGameInstance.GetInstance()
  if not GameInstance then
    Log.Error("[CloudGameUtil:DownloadCloudGameConfig] GameInstance is nil")
    return
  end
  local DownloadURLWithTS = CloudGameConfigURL .. "?t=" .. UE4.UNRCStatics.GetTimestampMicroseconds()
  local LocalFilePath = UE.UBlueprintPathsLibrary.Combine({
    UE.UBlueprintPathsLibrary.ProjectSavedDir(),
    CloudGameConfigName
  })
  GameInstance.OnDownloadFileResult:Clear()
  GameInstance.OnDownloadFileResult:Add(GameInstance, function(this, InURL, bSuccess, ErrorCode)
    Log.Debug(string.format("[CloudGameUtil:DownloadCloudGameConfig] download %s result: %s ErrorCode:%s", InURL, bSuccess, ErrorCode or "nil"))
    if InURL == DownloadURLWithTS then
      self:OnDownloadFinish()
    end
  end)
  UE4.UNRCStatics.HttpDownloadFile(DownloadURLWithTS, LocalFilePath)
end

function CloudGameUtil:OnDownloadTimeOut()
  Log.Debug("[CloudGameUtil:OnDownloadTimeOut] ")
  self:OnDownloadFinish(true)
end

function CloudGameUtil:OnDownloadFinish(isTimeOut)
  Log.Debug("[CloudGameUtil:OnDownloadFinish] ")
  if self.bGetCloudGameConfigResult then
    Log.Error("[CloudGameUtil:OnDownloadFinish] Invalid Callback")
    return
  end
  self.bGetCloudGameConfigResult = true
  local GameInstance = UE4.UNRCPlatformGameInstance.GetInstance()
  if GameInstance then
    GameInstance.OnDownloadFileResult:Clear()
  end
end

function CloudGameUtil:CheckCloudGameConfig()
  if not RocoEnv.PLATFORM_ANDROID then
    return false
  end
  Log.Debug("[CloudGameUtil:CheckCloudGameConfig] ")
  local LocalFilePath = UE.UBlueprintPathsLibrary.Combine({
    UE.UBlueprintPathsLibrary.ProjectSavedDir(),
    CloudGameConfigName
  })
  if not UE4.UBlueprintPathsLibrary.FileExists(LocalFilePath) then
    Log.Warning("[CloudGameUtil:CheckCloudGameConfig] Failed to find config:", LocalFilePath)
    return false
  end
  local LoadedConfig = UE4.UCloudGameUtils.LoadDecryptedData(LocalFilePath, CloudGameUtil.DEFAULT_ENCRYPTION_KEY)
  if not LoadedConfig then
    Log.Warning("[CloudGameUtil:CheckCloudGameConfig] Failed to load config")
    return false
  end
  Log.Debug("[CloudGameUtil:CheckCloudGameConfig] LoadedConfig:", LoadedConfig)
  local CloudGameConfigContent = rapidjson.decode(LoadedConfig)
  if not CloudGameConfigContent then
    Log.Warning("[CloudGameUtil:CheckCloudGameConfig] Failed to parse config")
    return false
  end
  Log.Dump(CloudGameConfigContent, 5, "CloudGameConfigContent")
  local Enable = false
  if CloudGameConfigContent.Enable then
    Enable = CloudGameConfigContent.Enable
    Log.Debug("[CloudGameUtil:CheckCloudGameConfig] Enable:", Enable)
  end
  if not Enable then
    Log.Warning("[CloudGameUtil:CheckCloudGameConfig] Enable is false")
    return false
  end
  local ChannelList
  if CloudGameConfigContent.ChannelList then
    ChannelList = CloudGameConfigContent.ChannelList
  end
  if not ChannelList then
    Log.Warning("[CloudGameUtil:CheckCloudGameConfig] ChannelList is nil")
    return false
  end
  local PackageChannel = UE.ULoginStatics.GetConfigChannel()
  for _, ChannelInfo in pairs(ChannelList) do
    Log.Debug("[CloudGameUtil:CheckCloudGameConfig] ChannelInfo:", ChannelInfo.Channel, ChannelInfo.Version, ChannelInfo.Url)
    if ChannelInfo.Channel == PackageChannel then
      self.CloudGameJumpUrl = ChannelInfo.Url
      self.LiteGameVersion = ChannelInfo.Version
      Log.Debug("[CloudGameUtil:CheckCloudGameConfig] PackageChannel:", PackageChannel)
      return true
    end
  end
  Log.Debug("[CloudGameUtil:CheckCloudGameConfig] ChannelList not found, PackageChannel:", PackageChannel)
  return false
end

function CloudGameUtil:GetCloudGameJumpUrl()
  return self.CloudGameJumpUrl or OfficialChannelUrl
end

function CloudGameUtil:GetLiteGameVersion(IsLiteGameInstall)
  if IsLiteGameInstall then
    return UE4.UNRCNativeUtils.GetOtherAppVersionName(CloudGameUtil.CloudGamePackageName)
  else
    return self.LiteGameVersion or "1.0.0.0"
  end
end

function CloudGameUtil:TryShowCloudGameDialog(CloudGameDialogText, bIsQuitGame)
  local CheckResult = CloudGameUtil:CheckCloudGameConfig()
  if CheckResult then
    local Context = DialogContext()
    local IsInstall = UE.UNRCDeviceInfoHelper.IsAppInstalled(CloudGameUtil.CloudGamePackageName)
    local LeftBtnText = IsInstall and LuaText.cloudgame_open or LuaText.cloudgame_download
    local LiteGameVer = CloudGameUtil:GetLiteGameVersion(IsInstall)
    local ContentText2 = string.format(LuaText.cloudgame_privacy_and_permission, LiteGameVer, string.format("<a id=\"%s\">%s</>", LuaText.cloudgame_privacy, "privacyUrl"), string.format("<a id=\"%s\">%s</>", LuaText.cloudgame_permission, "permissionUrl"))
    Context:SetTitle(LuaText.updateuimodule_26):SetContent(CloudGameDialogText):SetContent2(ContentText2):SetIfHideCloseBtn(true):SetMode(DialogContext.Mode.OK_CANCEL):SetCallback(self, function(this, result)
      if result then
        if UE.UNRCDeviceInfoHelper.IsAppInstalled(CloudGameUtil.CloudGamePackageName) then
          Log.Debug("[CloudGameUtil.TryShowCloudGameDialog] LaunchAndroidApp")
          UE4.UNRCNativeUtils.LaunchAndroidApp(CloudGameUtil.CloudGamePackageName)
        else
          Log.Debug("[CloudGameUtil.TryShowCloudGameDialog] DownloadLiteApp")
          CloudGameUtil:DownloadCloudGameApp()
        end
      elseif bIsQuitGame then
        Log.Debug("[CloudGameUtil.TryShowCloudGameDialog] QuitGame")
        UE4.UNRCStatics.QuitGame()
      else
        Log.Debug("[CloudGameUtil.TryShowCloudGameDialog] BackToSDKLoginSuccess")
        LoginUtils.SendEventToLoginFsm(LoginModuleEvent.BackToSDKLoginSuccess)
      end
    end):SetButtonText(LeftBtnText, LuaText.umg_minigame_giveup_1):SetCloseOnCancel(false):SetCloseOnOK(false):SetContentText2OnRichTextClickHandler(self, function(this, Key)
      Log.Debug("[CloudGameUtil.TryShowCloudGameDialog] RichTextClick Key:", Key)
      if CloudGameUtil.PopupUrlData[Key] then
        UE4.UWebViewStatics.OpenURL(CloudGameUtil.PopupUrlData[Key])
      end
    end)
    if not bIsQuitGame then
      Context:SetCloseOnCancel(true)
      Context:SetCloseOnOK(true)
    end
    _G.NRCModuleManager:DoCmd(_G.TipsModuleCmd.Dialog_OpenDialog, Context)
  end
  return CheckResult
end

function CloudGameUtil:DownloadCloudGameApp()
  if RocoEnv.PLATFORM_ANDROID then
    local Url = CloudGameUtil:GetCloudGameJumpUrl()
    Log.Debug("[CloudGameUtil:DownloadCloudGameApp] Url:", Url)
    if Url then
      _G.NRCEventCenter:DispatchEvent(UpdateUIModuleEvent.ReportDownloadBtnClick, LoginEnum.DownloadReportType.CloudGameDownloadBtn)
      UE4.UWebViewStatics.OpenUrl(Url)
    end
  end
end

function CloudGameUtil:GenerateEncryptFile()
  Log.Debug("[CloudGameUtil:GenerateEncryptFile] ")
  local JsonConfigFile = UE.UBlueprintPathsLibrary.Combine({
    UE.UBlueprintPathsLibrary.ProjectSavedDir(),
    CloudGameConfigName .. ".json"
  })
  if not UE4.UBlueprintPathsLibrary.FileExists(JsonConfigFile) then
    Log.Warning("[CloudGameUtil:GenerateEncryptFile] Failed to find JsonConfigFile:", JsonConfigFile)
    return false
  end
  Log.Debug("[CloudGameUtil:GenerateEncryptFile] JsonConfigFile:", JsonConfigFile)
  JsonConfigFile = UE4.UBlueprintPathsLibrary.ConvertRelativePathToFull(JsonConfigFile)
  Log.Debug("[CloudGameUtil:GenerateEncryptFile] ConvertRelativePathToFull JsonConfigFile:", JsonConfigFile)
  local JsonContent, Success = UE4.UNRCStatics.LoadToString(JsonConfigFile)
  if not Success then
    Log.Error("[CloudGameUtil:GenerateEncryptFile] Failed to load JsonConfigFile:", JsonConfigFile)
    return false
  end
  Log.Debug("[CloudGameUtil:GenerateEncryptFile] Success:", Success, "JsonContent:", JsonContent)
  local EncryptPath = UE.UBlueprintPathsLibrary.Combine({
    UE.UBlueprintPathsLibrary.ProjectSavedDir(),
    CloudGameConfigName .. "_encrypt"
  })
  UE4.UCloudGameUtils.SaveEncryptedData(JsonContent, EncryptPath, CloudGameUtil.DEFAULT_ENCRYPTION_KEY)
  return true
end

function CloudGameUtil:GenerateDecryptFile()
  Log.Debug("[CloudGameUtil:GenerateDecryptFile] ")
  local LocalFilePath = UE.UBlueprintPathsLibrary.Combine({
    UE.UBlueprintPathsLibrary.ProjectSavedDir(),
    CloudGameConfigName
  })
  if not UE4.UBlueprintPathsLibrary.FileExists(LocalFilePath) then
    Log.Warning("[CloudGameUtil:GenerateDecryptFile] Failed to find config:", LocalFilePath)
    return false
  end
  local Content = UE4.UCloudGameUtils.LoadDecryptedData(LocalFilePath, CloudGameUtil.DEFAULT_ENCRYPTION_KEY)
  if not Content then
    Log.Warning("[CloudGameUtil:GenerateDecryptFile] Failed to load config")
    return false
  end
  Log.Debug("[CloudGameUtil:GenerateDecryptFile] Content:", Content)
  local JsonConfigFile = UE.UBlueprintPathsLibrary.Combine({
    UE.UBlueprintPathsLibrary.ProjectSavedDir(),
    CloudGameConfigName .. "_check.json"
  })
  local Success = UE4.UNRCStatics.WriteToFile(JsonConfigFile, Content)
  Log.Debug("[CloudGameUtil:GenerateDecryptFile] Success:", Success)
  return true
end

return CloudGameUtil

local GCloudEndPoints = require("Core.Service.GCloud.GCloudEndPoints")
local rapidjson = require("rapidjson")
local UpdateBaseTask = require("Core.Service.GCloud.Tasks.UpdateBaseTask")
local Base = UpdateBaseTask
local UpdateAppTask = Base:Extend("UpdateAppTask")

function UpdateAppTask:FillInfo(InitInfo, PathInfo)
  InitInfo.updateType = UE.DolphinUpdateInitType.UpdateInitType_OnlyProgram
end

function UpdateBaseTask:GetMaskTaskNum()
  return 2
end

function UpdateBaseTask:GetMaxPerTaskNum()
  return 15
end

function UpdateAppTask:CreateInfo()
  local AppInfo = _G.App
  local InitInfo = UE.DolphinInitInfo()
  local PathInfo = UE.DolphinPathInfo()
  InitInfo.updateType = UE.DolphinUpdateInitType.UpdateInitType_OnlyProgram
  InitInfo.channelId = AppInfo:GetDolphinChannel()
  InitInfo.connectorType = 2
  InitInfo:SetUpdateUrl(GCloudEndPoints:GetDolphinUrl())
  InitInfo:SetAppVersion(AppInfo:GetAppVersion())
  InitInfo:SetSrcVersion(AppInfo:GetResVersion())
  InitInfo:SetStrDolphinDownloadFuncDict(rapidjson.encode({
    OptiHttpConfig_uEnableAverageShardingStrategy = 100,
    OptiHttpConfig_uAverageShardingSize = 3145728,
    OptiHttpConfig_uEnableDynamicExpansionMaxTask = 100,
    OptiHttpConfig_uEnableReuseRedirectHttp = 100,
    bUseDLProConfig = 1,
    uDLMaxTaskNum = self:GetMaskTaskNum(),
    uDLMaxPerTaskNum = self:GetMaxPerTaskNum(),
    uDLPollingTime = 5000,
    uDLMaxSpeed = 104875600
  }))
  Log.Debug(AppInfo:GetDolphinChannel(), GCloudEndPoints:GetDolphinUrl(), AppInfo:GetAppVersion(), AppInfo:GetResVersion())
  if RocoEnv.PLATFORM == "PLATFORM_ANDROID" or RocoEnv.PLATFORM == "PLATFORM_OPENHARMONY" then
    local PathSegs = {
      UE.UBlueprintPathsLibrary.ProjectPersistentDownloadDir(),
      "UE4Game",
      "NRC",
      "NRC",
      "Saved",
      "Dolphin"
    }
    local DolphinPath = UE.UBlueprintPathsLibrary.Combine(PathSegs)
    Log.Debug("[UpdateAppTask] DolphinPath:", DolphinPath)
    PathInfo:SetDolphinPath(DolphinPath)
    PathInfo:SetUpdatePath(DolphinPath)
    PathInfo:SetIfsPath(DolphinPath)
  else
    PathInfo:SetDolphinPath(self:MakeSavedPath("Dolphin"))
    PathInfo:SetUpdatePath(self:MakeSavedPath(""))
    PathInfo:SetIfsPath(self:MakeSavedPath(""))
  end
  if (RocoEnv.PLATFORM == "PLATFORM_ANDROID" or RocoEnv.PLATFORM == "PLATFORM_OPENHARMONY") and self.DolphinInstance then
    PathInfo:SetCurApkPath(self.DolphinInstance:GetAPKFilePath())
  end
  return InitInfo, PathInfo
end

function UpdateAppTask:OnDolphinVersionInfo(NewVersionInfo)
  local V1 = NewVersionInfo.versionNumberOne
  local V2 = NewVersionInfo.versionNumberTwo
  local V3 = NewVersionInfo.versionNumberThree
  local V4 = NewVersionInfo.versionNumberFour
  local Version = string.format("%d.%d.%d.%d", V1, V2, V3, V4)
  local AppVersion = _G.AppMain:GetAppVersion()
  Log.Debug(string.format("[UpdateAppTask:OnDolphinVersionInfo] NewVersion: %s, CurVersion: %s", Version, AppVersion))
  self.isAuditVersion = NewVersionInfo.isAuditVersion
  _G.AppMain:SetAuditVersion(self.isAuditVersion)
  self.userDefineStr = NewVersionInfo:GetUserDefineString()
  Log.Debug("UpdateAppTask NewVersionInfo.userDefineStr  :  ", self.userDefineStr)
  _G.AppMain:SetUserDefineStr(self.userDefineStr)
  Log.Debug("UpdateAppTask NewVersionInfo.isAuditVersion  :  ", self.isAuditVersion)
  if self:CompareVersion(AppVersion, Version) then
    Log.Warning("\229\186\148\231\148\168\231\137\136\230\156\172\233\171\152\228\186\142Dolphin\228\184\139\229\143\145\231\154\132\231\137\136\230\156\172\239\188\140\232\183\179\232\191\135\230\155\180\230\150\176\233\152\182\230\174\181", AppVersion, Version)
    self:OnDolphinSuccess()
    return
  end
  Base.OnDolphinVersionInfo(self, NewVersionInfo)
end

return UpdateAppTask

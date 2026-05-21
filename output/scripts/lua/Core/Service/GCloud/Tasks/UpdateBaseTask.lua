local GCloudEndPoints = require("Core.Service.GCloud.GCloudEndPoints")
local rapidjson = require("rapidjson")
local Delegate = require("Utils.Delegate")
local UpdateBaseTask = Class("UpdateBaseTask")

function UpdateBaseTask:Ctor()
  _G.NRCEventCenter:RegisterEvent(self.name, self, _G.NRCGlobalEvent.OnPrePIEEnded, self.Uninit)
  self.CurrentStage = 0
  self.StageStartTime = 0
  self.LastUpdateTime = 0
  self.AverageSpeed = 0
  self.CurrentSpeed = 0
  self.TotalDownloadSize = 0
  self.LastDownloadSize = 0
  self.NewVersionDelegate = Delegate()
  self.ProgressDelegate = Delegate()
  self.ErrorDelegate = Delegate()
  self.SuccessDelegate = Delegate()
  self.NetworkChangedDelegate = Delegate()
end

function UpdateBaseTask:PreInit()
  local World = _G.UE4Helper.GetCurrentWorld()
  self.DolphinInstance = NewObject(UE.UDolphinImpl, World)
  self.DolphinInstance_Ref = UnLua.Ref(self.DolphinInstance)
  self.Observer = NewObject(UE.UDolphinObserver, World, "", "Core.Service.GCloud.DolphinObserver", self)
  self.Observer_Ref = UnLua.Ref(self.Observer)
end

function UpdateBaseTask:CreateInfo()
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
  PathInfo:SetDolphinPath(self:MakeSavedPath("Dolphin"))
  PathInfo:SetUpdatePath(self:MakeSavedPath(""))
  PathInfo:SetIfsPath(self:MakeSavedPath(""))
  if (RocoEnv.PLATFORM == "PLATFORM_ANDROID" or RocoEnv.PLATFORM == "PLATFORM_OPENHARMONY") and self.DolphinInstance then
    PathInfo:SetCurApkPath(self.DolphinInstance:GetAPKFilePath())
  end
  return InitInfo, PathInfo
end

function UpdateBaseTask:GetMaskTaskNum()
  return 9
end

function UpdateBaseTask:GetMaxPerTaskNum()
  return 3
end

function UpdateBaseTask:FillInfo(InitInfo, PathInfo)
  InitInfo.updateType = UE.DolphinUpdateInitType.UpdateInitType_OnlyProgram
end

function UpdateBaseTask:Init()
  self:PreInit()
  if not self.DolphinInstance then
    return false
  end
  if not self.Observer then
    return false
  end
  local InitInfo, PathInfo = self:CreateInfo()
  self:FillInfo(InitInfo, PathInfo)
  local Result = self.DolphinInstance:Init(self.Observer, InitInfo, PathInfo)
  if not Result then
    Log.Error("Dolphin\229\136\157\229\167\139\229\140\150\229\164\177\232\180\165\239\188\129")
    return false
  end
  return Result
end

function UpdateBaseTask:StartCheck()
  if not self.DolphinInstance then
    return
  end
  self.DolphinInstance:CheckAppUpdate()
end

function UpdateBaseTask:Uninit()
  self.NewVersionDelegate:Clear()
  self.ProgressDelegate:Clear()
  self.ErrorDelegate:Clear()
  self.SuccessDelegate:Clear()
  self.NetworkChangedDelegate:Clear()
  _G.NRCEventCenter:UnRegisterEvent(self, _G.NRCGlobalEvent.OnPrePIEEnded, self.Uninit)
  self:DestroyNetworkObserver()
  if self.DolphinInstance and UE.UObject.IsValid(self.DolphinInstance) then
    self.DolphinInstance:CancelUpdate()
    self.DolphinInstance:Uninit()
    self.DolphinInstance = nil
    self.DolphinInstance_Ref = nil
  end
  self.Observer = nil
  self.Observer_Ref = nil
end

function UpdateBaseTask:OnDolphinVersionInfo(NewVersionInfo)
  Log.Debug("Here comes version info!", NewVersionInfo.versionNumberOne, NewVersionInfo.versionNumberTwo, NewVersionInfo.versionNumberThree, NewVersionInfo.versionNumberFour)
  if NewVersionInfo.isNeedUpdating then
    if self.DolphinInstance then
      self.DolphinInstance:EnableHighSpeedCDN()
    end
    self.NewVersionDelegate:Invoke(self, NewVersionInfo)
  else
    self:OnDolphinSuccess()
  end
end

function UpdateBaseTask:ContinueUpdate(bContinue)
  if not self.DolphinInstance then
    return
  end
  if bContinue then
    self:CreateNetworkObserver()
  end
  self.DolphinInstance:ContinueUpdate(bContinue)
end

function UpdateBaseTask:FormatBytes(Bytes)
  local units = {
    "B",
    "KB",
    "MB",
    "GB",
    "TB"
  }
  local i = 1
  while Bytes >= 1024 and i < #units do
    Bytes = Bytes / 1024
    i = i + 1
  end
  return string.format("%.1f %s", Bytes, units[i])
end

function UpdateBaseTask:GetCurrentSpeed()
  return string.format("%s/S", self:FormatBytes(self.CurrentSpeed))
end

function UpdateBaseTask:GetAverageSpeed()
  return string.format("%s/S", self:FormatBytes(self.AverageSpeed))
end

function UpdateBaseTask:OnDolphinProgress(CurVersionStage, TotalSize, NowSize)
  local Now = _G.UpdateManager.Timestamp
  if self.CurrentStage ~= CurVersionStage then
    self.StageStartTime = Now
    self.LastUpdateTime = self.StageStartTime
    self.TotalDownloadSize = NowSize
    self.LastDownloadSize = NowSize
    self.CurrentSpeed = 0
    self.AverageSpeed = 0
  else
    self.AverageSpeed = (NowSize - self.TotalDownloadSize) / (Now - self.StageStartTime)
    local DeltaTime = Now - self.LastUpdateTime
    if DeltaTime > 1 then
      self.CurrentSpeed = (NowSize - self.LastDownloadSize) / (Now - self.LastUpdateTime)
      self.LastDownloadSize = NowSize
      self.LastUpdateTime = Now
    end
  end
  self.CurrentStage = CurVersionStage
  self.ProgressDelegate:Invoke(self, CurVersionStage, TotalSize, NowSize)
end

function UpdateBaseTask:OnDolphinError(CurVersionStage, ErrorCode)
  Log.Error("Dolphin\230\138\165\233\148\153\228\186\134", CurVersionStage, ErrorCode)
  self.DolphinInstance:SetCurState(UE.EUpdateState.FAILED)
  self.ErrorDelegate:Invoke(self, CurVersionStage, ErrorCode)
end

function UpdateBaseTask:OnDolphinSuccess()
  Log.Debug("Dolphin\230\136\144\229\138\159\228\186\134")
  self.DolphinInstance:SetCurState(UE.EUpdateState.SUCCEED)
  self.SuccessDelegate:Invoke(self, false)
end

function UpdateBaseTask:OnDolphinNoticeInstallApk(ApkUrl)
  Log.Debug("Dolphin\230\143\144\231\164\186\233\156\128\232\166\129\229\174\137\232\163\133Apk", ApkUrl)
  self.InstallAPKPath = ApkUrl
  self.SuccessDelegate:Invoke(self, true)
end

function UpdateBaseTask:InstallAPK()
  if not self.DolphinInstance then
    return
  end
  if string.IsNilOrEmpty(self.InstallAPKPath) then
    Log.Debug("\230\178\161\230\156\137\229\143\145\231\142\176\233\156\128\232\166\129\229\174\137\232\163\133\231\154\132APK")
    return
  end
  Log.Debug("\230\152\190\231\164\186\229\174\137\232\163\133\232\183\175\229\190\132", self.InstallAPKPath)
  self.DolphinInstance:InstallAPK(self.InstallAPKPath)
end

function UpdateBaseTask:OnDolphinFirstExtractSuccess()
  Log.Debug("Dolphin\230\143\144\231\164\186\233\166\150\229\140\133\232\167\163\229\142\139\229\174\140\230\136\144\228\186\134")
  self.DolphinInstance:SetCurState(UE.EUpdateState.SUCCEED)
end

function UpdateBaseTask:OnActionMsgArrive(Message)
  Log.Debug("Dolphin\230\143\144\231\164\186:", Message)
end

function UpdateBaseTask:CreateNetworkObserver()
  if RocoEnv.PLATFORM_WINDOWS then
    return
  end
  if self.NetworkObserver then
    return
  end
  local World = _G.UE4Helper.GetCurrentWorld()
  self.NetworkObserver = NewObject(UE.UNetworkStatusObserver, World, "", "Core.Service.GCloud.NetworkStatusObserver", self)
  self.NetworkObserver_Ref = UnLua.Ref(self.NetworkObserver)
  UE.UNetworkStatics.AddObserver(self.NetworkObserver)
end

function UpdateBaseTask:DestroyNetworkObserver()
  if RocoEnv.PLATFORM_WINDOWS then
    return
  end
  if not self.NetworkObserver then
    return
  end
  UE.UNetworkStatics.RemoveObserver(self.NetworkObserver)
  self.NetworkObserver = nil
  self.NetworkObserver_Ref = nil
end

function UpdateBaseTask:MakePath(SavedOrContent, Sub)
  local PathSegs
  local Prefix = SavedOrContent and "Saved" or "Content"
  if RocoEnv.PLATFORM == "PLATFORM_ANDROID" or RocoEnv.PLATFORM == "PLATFORM_OPENHARMONY" then
    PathSegs = {
      UE.UNRCStatics.GetFilePathBase(),
      "UE4Game",
      "NRC",
      "NRC",
      Prefix
    }
  else
    PathSegs = {
      UE.UBlueprintPathsLibrary.ProjectDir(),
      Prefix
    }
  end
  if not string.IsNilOrEmpty(Sub) then
    table.insert(PathSegs, Sub)
  end
  local Path = UE.UBlueprintPathsLibrary.Combine(PathSegs)
  if RocoEnv.PLATFORM ~= "PLATFORM_ANDROID" and RocoEnv.PLATFORM ~= "PLATFORM_OPENHARMONY" then
    Path = UE.UNRCStatics.ConvertToAbsolutePath(Path, false)
  end
  UE.UNRCStatics.MakeDirectory(Path)
  Log.Debug("Returning path", Path)
  return Path
end

function UpdateBaseTask:MakeSavedPath(Sub)
  return self:MakePath(true, Sub)
end

function UpdateBaseTask:MakeContentPath(Sub)
  return self:MakePath(false, Sub)
end

function UpdateBaseTask:SplitVersion(Version)
  local Spat = string.Split(Version, ".")
  if not Spat then
    return 0, 0, 0, 0
  end
  return tonumber(Spat[1] or "0"), tonumber(Spat[2] or "0"), tonumber(Spat[3] or "0"), tonumber(Spat[4] or "0")
end

function UpdateBaseTask:CompareVersion(One, Two)
  local O1, O2, O3, O4 = self:SplitVersion(One)
  local T1, T2, T3, T4 = self:SplitVersion(Two)
  if O1 ~= T1 then
    return O1 > T1
  end
  if O2 ~= T2 then
    return O2 > T2
  end
  if O3 ~= T3 then
    return O3 > T3
  end
  return O4 >= T4
end

return UpdateBaseTask

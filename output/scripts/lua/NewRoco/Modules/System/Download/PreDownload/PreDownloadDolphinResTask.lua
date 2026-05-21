local UpdateBaseTask = require("Core.Service.GCloud.Tasks.UpdateBaseTask")
local Base = UpdateBaseTask
local PreDownloadDolphinResTask = Base:Extend("PreDownloadDolphinResTask")

function PreDownloadDolphinResTask:Ctor()
  Base.Ctor(self)
end

function PreDownloadDolphinResTask:FillInfo(InitInfo, PathInfo)
  InitInfo.updateType = UE.DolphinUpdateInitType.UpdateInitType_SourceCheckAndSync
  InitInfo:SetAppVersion(_G.NRCPreDownloadManager:GetPreDownloadAppVersion())
  InitInfo:SetSrcVersion(_G.NRCPreDownloadManager:GetPreDownloadResVersion())
  PathInfo:SetDolphinPath(_G.NRCPreDownloadManager:GetDolphinRootDir())
  PathInfo:SetUpdatePath(_G.NRCPreDownloadManager:GetDolphinRootDir())
  PathInfo:SetIfsPath(_G.NRCPreDownloadManager:GetDolphinRootDir())
end

function PreDownloadDolphinResTask:OnDolphinVersionInfo(NewVersionInfo)
  self.HadNewVersion = NewVersionInfo.isNeedUpdating
  self.UpdateVersion = string.format("%d.%d.%d.%d", NewVersionInfo.versionNumberOne, NewVersionInfo.versionNumberTwo, NewVersionInfo.versionNumberThree, NewVersionInfo.versionNumberFour)
  Log.Debug(string.format("[PreDownloadDolphinResTask:OnDolphinVersionInfo] NewResVer:%s, isNeedUpdating:%s, isForcedUpdating:%s", self.UpdateVersion, tostring(self.HadNewVersion), tostring(NewVersionInfo.isForcedUpdating)))
  if self.HadNewVersion then
    NewVersionInfo.isForcedUpdating = true
  end
  Base.OnDolphinVersionInfo(self, NewVersionInfo)
end

return PreDownloadDolphinResTask

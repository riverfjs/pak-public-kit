local LoadingProfiler = NRCClass:Extend("LoadingProfiler")
_G.LoadingProfilerCheckPoint = {
  None = "None",
  EnterScene = "EnterScene",
  EnterMap = "EnterMap",
  PostMapLoaded = "PostMapLoaded",
  OpenPanel = "OpenPanel",
  OpenPanelComplete = "OpenPanelComplete",
  ShowInteractItem = "ShowInteractItem",
  InteractMainInteract = "InteractMainInteract",
  InteractItemOnSelect = "InteractItemOnSelect",
  Battle_StartBattle = "Battle_StartBattle",
  Battle_RoundStart = "Battle_RoundStart"
}

function LoadingProfiler:SetEnable(value)
  self.isEnable = value
end

function LoadingProfiler:Start()
  self.checkPointLst = {}
  self.isWriteCheckPoint = true
  if self:IsEnable() then
    self.nameFix = math.random()
    UE4.UNRCStatics.OpenFileForStreamingWrite(self:GetFileName())
    self:RegisterEvent()
    Log.Warning("EnableLoadingProfiler")
    NRCResourceManager:BindProfilerFunction(self, self.OnProfiler)
  end
end

function LoadingProfiler:OnProfiler(pakPath, priority)
  Log.Debug("LoadingProfiler:", pakPath, priority)
  UE4.UNRCStatics.StreamingWriteFile(self:GetFileName(), pakPath .. "," .. priority .. "\n")
end

function LoadingProfiler:Stop()
  if self:IsEnable() then
    Log.Debug("LoadingProfiler:Stop()")
    UE4.UNRCStatics.CloseFileForStreamingWrite(self:GetFileName())
    self:UnRegisterEvent()
  end
end

function LoadingProfiler:GetFileName()
  local Name = "LoadingProfiler" .. tostring(self.nameFix) .. ".csv"
  local File = string.format("%s%s", UE4.UBlueprintPathsLibrary.ProjectSavedDir(), Name)
  File = UE4.UBlueprintPathsLibrary.ConvertRelativePathToFull(File)
  Log.Debug("GetFileName:", File)
  return File
end

function LoadingProfiler:RegisterEvent()
end

function LoadingProfiler:UnRegisterEvent()
end

function LoadingProfiler:IsEnable()
  return self.isEnable
end

function LoadingProfiler:GetTime()
  return UE4.UNRCStatics.GetMilliSeconds()
end

function LoadingProfiler:CheckPoint(pointType, param)
  if not self:IsEnable() then
    return
  end
  param = param or "Nil"
  Log.Debug("LoadingProfiler CheckPoint:", pointType, param)
  if self.isWriteCheckPoint then
    UE4.UNRCStatics.StreamingWriteFile(self:GetFileName(), "CheckPoint:" .. pointType .. "-" .. param .. "," .. UE4.UNRCStatics.GetMilliSeconds() .. "\n")
  end
  local data = {
    pt = pointType,
    time = self:GetTime(),
    param = param
  }
  table.insert(self.checkPointLst, data)
end

function LoadingProfiler:ClearCheckPoint()
  self.checkPointLst = {}
end

function LoadingProfiler:SaveJson()
end

return LoadingProfiler

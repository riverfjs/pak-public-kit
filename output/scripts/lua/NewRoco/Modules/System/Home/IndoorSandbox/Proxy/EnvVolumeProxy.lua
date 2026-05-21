local EnvVolumeProxy = Class("EnvVolumeProxy")

function EnvVolumeProxy:Ctor(Actor, RoomId)
  self.Actor = Actor
  self.RoomId = RoomId
  self:CollectDefault()
end

function EnvVolumeProxy:CollectDefault()
  HomeIndoorSandbox:LogWarn("EnvVolumeProxy", self, self.Actor)
  self.DefaultEnvSystemSetting = self:GetEnvSystemSetting()
  self.DefaultEnvSystemSettingLow = self:GetEnvSystemSettingLow()
  self.DefaultTodVolumeIndex = self:GetEnvVolumeIndex()
  self.DefaultBlendWeight = self:GetBlendWeight() or 1
end

function EnvVolumeProxy:SetActorHiddenInGame(bHidden)
  if HomeIndoorSandbox:Ensure(self.Actor and UE.UObject.IsValid(self.Actor), "logical error", self.Actor) then
    self.Actor:SetActorHiddenInGame(bHidden)
    if bHidden then
      self.Actor.BlendWeight = 0
    else
      self.Actor.BlendWeight = self.DefaultBlendWeight
    end
  end
end

function EnvVolumeProxy:GetEnvSystemSetting()
  if HomeIndoorSandbox:Ensure(self.Actor and UE.UObject.IsValid(self.Actor), "logical error", self.Actor) then
    return self.Actor.EnvSystemSetting
  end
end

function EnvVolumeProxy:GetEnvSystemSettingLow()
  if HomeIndoorSandbox:Ensure(self.Actor and UE.UObject.IsValid(self.Actor), "logical error", self.Actor) then
    return self.Actor.EnvSystemSettingLow
  end
end

function EnvVolumeProxy:GetBlendWeight()
  if HomeIndoorSandbox:Ensure(self.Actor and UE.UObject.IsValid(self.Actor), "logical error", self.Actor) then
    return self.Actor.BlendWeight
  end
end

function EnvVolumeProxy:GetEnvVolumeIndex()
  if HomeIndoorSandbox:Ensure(self.Actor and UE.UObject.IsValid(self.Actor), "logical error", self.Actor) then
    return self.Actor.TodVolumeIndex
  end
end

function EnvVolumeProxy:ApplySystemSetting(EnvSystemSetting, EnvSystemSettingLow)
  EnvSystemSetting = EnvSystemSetting or self.DefaultEnvSystemSetting
  self:InternalSetSystemSetting(EnvSystemSetting, EnvSystemSettingLow)
end

function EnvVolumeProxy:InternalSetSystemSetting(EnvSystemSetting, EnvSystemSettingLow)
  if HomeIndoorSandbox:Ensure(self.Actor and UE.UObject.IsValid(self.Actor), "logical error", self.Actor) then
    self.Actor.EnvSystemSetting = EnvSystemSetting
    self.Actor.EnvSystemSettingLow = EnvSystemSettingLow
    self:PostEnvSystemSettingChanged()
  end
end

function EnvVolumeProxy:PostChanged()
  if HomeIndoorSandbox:Ensure(self.Actor and UE.UObject.IsValid(self.Actor), "logical error", self.Actor) then
    self:PostEnvSystemSettingChanged()
  end
end

function EnvVolumeProxy:PostEnvSystemSettingChanged()
  if HomeIndoorSandbox.HomeEditServ:InEditMode() and self.RoomId == HomeIndoorSandbox.HomeEditServ.EditRoomId then
    self.Actor.bUnbound = true
    self.Actor.TodVolumeIndex = 50
  else
    self.Actor.bUnbound = false
    self.Actor.TodVolumeIndex = self.DefaultTodVolumeIndex or 0
  end
end

return EnvVolumeProxy

local Delegate = require("Utils.Delegate")
local SelfieCameraResource = Class()

function SelfieCameraResource:Ctor()
  self.SelfieCamera = nil
  self.SelfieCameraClass = nil
  self.SelfieCameraClassRef = nil
  self.SelfieCameraClassRequest = nil
  self.bPendingSpawn = false
  self.OnSpawned = Delegate()
end

function SelfieCameraResource:ConditionalLoad()
  if not self.SelfieCameraClassRequest and (not self.SelfieCameraClass or not UE.UObject.IsValid(self.SelfieCameraClass)) then
    self.SelfieCameraClassRequest = NRCResourceManager:LoadResAsync(self, "Blueprint'/Game/NewRoco/Modules/System/TakePhotos/Res/BP_SelfieCamera.BP_SelfieCamera_C'", 255, -1, self.OnLoad)
  end
end

function SelfieCameraResource:OnLoad(Request, Asset)
  self.SelfieCameraClassRequest = nil
  self.SelfieCameraClass = Asset
  self.SelfieCameraClassRef = Asset and UnLua.Ref(Asset)
  if self.bPendingSpawn then
    self:InternalSpawn()
  end
end

function SelfieCameraResource:IsCreating()
  return self.SelfieCameraClassRequest
end

function SelfieCameraResource:IsCreated()
  return self.SelfieCamera and UE4.UObject.IsValid(self.SelfieCamera)
end

function SelfieCameraResource:GetCamera()
  return self.SelfieCamera
end

function SelfieCameraResource:ConditionalSpawn(WorldTransform)
  self:ConditionalLoad()
  if self:IsCreating() or self:IsCreated() then
    return
  end
  self.SelfieCamera = nil
  self.SpawnWorldTransform = WorldTransform
  if self.SelfieCameraClass and UE.UObject.IsValid(self.SelfieCameraClass) then
    self:InternalSpawn()
  else
    self.bPendingSpawn = true
  end
end

function SelfieCameraResource:InternalSpawn()
  self.bPendingSpawn = false
  if self.SelfieCameraClass and UE.UObject.IsValid(self.SelfieCameraClass) then
    self.SelfieCamera = UE4Helper.GetCurrentWorld():Abs_SpawnActor(self.SelfieCameraClass, self.SpawnWorldTransform, UE4.ESpawnActorCollisionHandlingMethod.AlwaysSpawn)
    self:UnProcess()
    self.OnSpawned:Invoke(self.SelfieCamera)
  end
end

function SelfieCameraResource:Process()
  if self.SelfieCamera and UE4.UObject.IsValid(self.SelfieCamera) then
    self.SelfieCamera:SetActorHiddenInGame(false)
    self.SelfieCamera:SetActorEnableCollision(true)
    return self.SelfieCamera
  end
  return nil
end

function SelfieCameraResource:UnProcess()
  if self.SelfieCamera then
    self.SelfieCamera:SetActorHiddenInGame(true)
    self.SelfieCamera:SetActorEnableCollision(false)
  end
end

function SelfieCameraResource:DestroyCamera()
  self.bPendingSpawn = false
  self.SpawnWorldTransform = nil
  if self.SelfieCamera and UE.UObject.IsValid(self.SelfieCamera) then
    self.SelfieCamera:K2_DestroyActor()
  end
  self.SelfieCamera = nil
end

return SelfieCameraResource

local CameraHolder = NRCClass()

function CameraHolder:Ctor(Klass)
  self.MainCamera = nil
  self.BackUpCamera = nil
  self.CameraActorClass = Klass
  self.ControllerCache = nil
  self.CameraID = 0
end

function CameraHolder:Spawn()
  local Camera = UE4Helper.GetCurrentWorld():SpawnActor(self.CameraActorClass or UE.ACameraActor, UE.FTransform(), UE4.ESpawnActorCollisionHandlingMethod.AlwaysSpawn)
  if RocoEnv.IS_EDITOR then
    self.CameraID = self.CameraID + 1
    Camera:SetActorLabelNoFlush(string.format("CameraHolder%d", self.CameraID))
  end
  local CameraComp = Camera:GetComponentByClass(UE4.UCameraComponent)
  CameraComp.FieldOfView = 90
  CameraComp.bConstrainAspectRatio = false
  return Camera
end

function CameraHolder:GetMainCamera()
  if not self.MainCamera or not UE.UObject.IsValid(self.MainCamera) then
    self.MainCamera = self:Spawn()
  end
  return self.MainCamera
end

function CameraHolder:GetMainComponent()
  return self:GetMainCamera().CameraComponent
end

function CameraHolder:GetBackUpCamera()
  if not self.BackUpCamera or not UE.UObject.IsValid(self.BackUpCamera) then
    self.BackUpCamera = self:Spawn()
  end
  return self.BackUpCamera
end

function CameraHolder:GetBackUpComponent()
  return self:GetBackUpCamera().CameraComponent
end

function CameraHolder:SwapCamera()
  local Main = self.MainCamera
  self.MainCamera = self.BackUpCamera
  self.BackUpCamera = Main
  if not self.MainCamera or not UE.UObject.IsValid(self.MainCamera) then
    return
  end
  local MainCameraComponent = self.MainCamera.CameraComponent
  if not MainCameraComponent or not UE.UObject.IsValid(MainCameraComponent) then
    return
  end
  if not self.BackUpCamera or not UE.UObject.IsValid(self.BackUpCamera) then
    return
  end
  local BackupCameraComponent = self.BackUpCamera.CameraComponent
  if not BackupCameraComponent or not UE.UObject.IsValid(BackupCameraComponent) then
    return
  end
  local MainSetting = MainCameraComponent.PostProcessSettings
  local BackupSetting = BackupCameraComponent.PostProcessSettings
  MainSetting.bOverride_MobileHQGaussian = BackupSetting.bOverride_MobileHQGaussian
  MainSetting.bMobileHQGaussian = BackupSetting.bMobileHQGaussian
  MainSetting.bOverride_DepthOfFieldScale = BackupSetting.bOverride_DepthOfFieldScale
  MainSetting.DepthOfFieldScale = BackupSetting.DepthOfFieldScale
  MainSetting.bOverride_DepthOfFieldFocalDistance = BackupSetting.bOverride_DepthOfFieldFocalDistance
  MainSetting.DepthOfFieldFocalDistance = BackupSetting.DepthOfFieldFocalDistance
  MainSetting.bOverride_DepthOfFieldFocalRegion = BackupSetting.bOverride_DepthOfFieldFocalRegion
  MainSetting.DepthOfFieldFocalRegion = BackupSetting.DepthOfFieldFocalRegion
  MainSetting.bOverride_DepthOfFieldNearTransitionRegion = BackupSetting.bOverride_DepthOfFieldNearTransitionRegion
  MainSetting.DepthOfFieldNearTransitionRegion = BackupSetting.DepthOfFieldNearTransitionRegion
  MainSetting.bOverride_DepthOfFieldFarTransitionRegion = BackupSetting.bOverride_DepthOfFieldFarTransitionRegion
  MainSetting.DepthOfFieldFarTransitionRegion = BackupSetting.DepthOfFieldFarTransitionRegion
end

function CameraHolder:GetCurrentCamera()
  local Controller = self:GetController()
  if self.MainCamera and UE.UObject.IsValid(self.MainCamera) and Controller:IsCurrentViewTarget(self.MainCamera) then
    return self.MainCamera
  elseif self.BackUpCamera and UE.UObject.IsValid(self.BackUpCamera) and Controller:IsCurrentViewTarget(self.BackUpCamera) then
    return self.BackUpCamera
  else
    return nil
  end
end

function CameraHolder:GetNextCamera()
  local BackUp = self:GetBackUpCamera()
  local Controller = self:GetController()
  if not Controller then
    Log.Error("Controller is nil")
    return self:GetBackUpCamera()
  end
  return self:GetBackUpCamera()
end

function CameraHolder:Activate(BlendTime, BlendFunc, BlendExp)
  local Controller = self:GetController()
  if not Controller then
    Log.Error("Failed to activate camera")
    return
  end
  local main_camera = self:GetMainCamera()
  if main_camera and Controller.PlayerCameraManager then
    main_camera:K2_SetActorTransform(UE4.FTransform(Controller.PlayerCameraManager:GetCameraRotation():ToQuat(), Controller.PlayerCameraManager:GetCameraLocation()), false, nil, false)
  end
  if self.MainCamera and Controller:IsCurrentViewTarget(self.MainCamera) then
    Controller:SetViewTargetWithBlend(self:GetBackUpCamera(), BlendTime, BlendFunc, BlendExp)
  else
    Controller:SetViewTargetWithBlend(self.MainCamera, 0.0, UE4.EViewTargetBlendFunction.VTBlend_Linear, 0.0)
    Controller:ChangeToCustomCamera(self:GetBackUpCamera(), BlendTime, BlendFunc, BlendExp)
  end
  self:SwapCamera()
end

function CameraHolder:Deactivate(BlendTime, BlendFunc, BlendExp)
  local Controller = self:GetController()
  if not Controller then
    Log.Error("Failed to activate camera")
    return
  end
  if self.MainCamera and Controller:IsCurrentViewTarget(self.MainCamera) then
    Controller:ReleaseRocoCamera(BlendTime, BlendFunc, BlendExp)
  end
  if self.BackUpCamera and Controller:IsCurrentViewTarget(self.BackUpCamera) then
    Controller:ReleaseRocoCamera(BlendTime, BlendFunc, BlendExp)
  end
end

function CameraHolder:GetController()
  if self.ControllerCache and UE.UObject.IsValid(self.ControllerCache) then
    return self.ControllerCache
  end
  local Player = _G.NRCModeManager:DoCmd(_G.PlayerModuleCmd.GET_LOCAL_PLAYER)
  if not Player then
    Log.Error("Fail to get player")
    return
  end
  self.ControllerCache = Player:GetUEController()
  return self.ControllerCache
end

function CameraHolder:GetCurrentViewTransform()
  local Controller = self:GetController()
  local Manager = Controller and Controller.PlayerCameraManager
  if not Manager then
    return UE.FTransform()
  end
  if not UE.UObject.IsValid(Manager) then
    return UE.FTransform()
  end
  local Location = Manager:GetCameraLocation()
  local Rotation = Manager:GetCameraRotation()
  local Transform = UE.FTransform(Rotation:ToQuat(), Location)
  return Transform
end

return CameraHolder

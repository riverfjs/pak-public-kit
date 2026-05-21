local UMG_HomeFurniturePreview_2_C = _G.NRCPanelBase:Extend("UMG_HomeFurniturePreview_2_C")

function UMG_HomeFurniturePreview_2_C:OnConstruct()
  self.actorIsolateWorld = nil
  UE4.UNRCQualityLibrary.SwitchNRCGameShadowMode(3)
  self.scale = 1
  self.deltaRotation = UE4.FRotator(0, 0, 0)
  self.camera = self.PreviewWorld:getActorByName("DefaultSceneCapture")
  self.captureComponent = self.camera:GetComponentByClass(UE4.USceneCaptureComponent2D)
  self.captureComponent.showOnlyActors:Clear()
  UE4.UNRCStatics.ChangeTextureToCustomSize(self.captureComponent.TextureTarget, 960, 600)
end

function UMG_HomeFurniturePreview_2_C:SetPetPreview(modelPath, scale, cameraHigh, deltaRotation, bNeedRotate)
  if not modelPath then
    return
  end
  if UE.UObject.IsValid(self.actorIsolateWorld) then
    self.lastRotation = self.actorIsolateWorld:K2_GetActorRotation()
    self.PreviewWorld:DestroyActor(self.actorIsolateWorld)
    self.actorIsolateWorld = nil
  end
  self.scale = scale
  self.deltaRotation = deltaRotation
  self.cameraHigh = cameraHigh
  self.bNeedRotate = bNeedRotate
  self:LoadPanelRes(modelPath, 255, self.OnLoadModelFinish, nil, nil)
end

function UMG_HomeFurniturePreview_2_C:OnLoadModelFinish(resRequest, modelClass)
  if not modelClass or not modelClass:IsValid() then
    Log.ErrorFormat("UMG_HomePetPreview_C:OnLoadModelFinish \230\168\161\229\158\139\232\183\175\229\190\132\233\148\153\232\175\175 [%s].", resRequest or "")
    return
  end
  self.actorIsolateWorld = self.PreviewWorld:SetPreview(modelClass)
  self:OnFurnitureLoaded(self.actorIsolateWorld)
end

function UMG_HomeFurniturePreview_2_C:OnFurnitureLoaded(actor)
  if not actor then
    Log.Error("no valid actor UMG_HomePetPreview_C:OnPetLoaded")
    return
  end
  local scale = self.scale
  actor:SetActorScale3D(UE4.FVector(scale, scale, scale))
  local boxComponent = actor:GetComponentByClass(UE4.UNRCHomeBoxComponent)
  local unscaledHalfHeight
  if boxComponent then
    unscaledHalfHeight = boxComponent:K2_GetComponentLocation().Z / scale
  else
    unscaledHalfHeight = 70
  end
  self.unscaledHalfHeight = unscaledHalfHeight
  self.halfHeight = unscaledHalfHeight * scale
  self.captureComponent.showOnlyActors:Clear()
  self.captureComponent.showOnlyActors:Add(actor)
  local location = actor:K2_GetActorLocation()
  local rotation = actor:K2_GetActorRotation()
  local forwardVec = UE4.UKismetMathLibrary.GetForwardVector(rotation)
  local upVec = UE4.UKismetMathLibrary.GetUpVector(rotation)
  local actorRotation = UE4.FRotator(rotation.Pitch, rotation.Yaw - 90, rotation.Roll)
  actor:K2_SetActorRotation(actorRotation, false)
  local cameraLocation = location + forwardVec * 1000 + upVec * self.halfHeight * 2 + UE4.FVector(0, 0, self.cameraHigh)
  local targetLocation = location + upVec * self.halfHeight
  self.initLoaction = location
  self.firstRotation = actorRotation
  if self.bNeedRotate then
    self:FurnitureRotate(UE4.FRotator(-90, 0, 0))
    actorRotation = actor:K2_GetActorRotation()
    location = actor:K2_GetActorLocation()
  end
  self.initRotation = actorRotation
  self.actorInitLocation = location
  local cameraRotation = UE4.UKismetMathLibrary.FindLookAtRotation(cameraLocation, targetLocation)
  self.cameraLocation = cameraLocation
  self.camera:K2_SetActorLocation(cameraLocation, false, nil, false)
  self.camera:K2_SetActorRotation(cameraRotation, false)
  self:FurnitureRotate(UE4.FRotator(0, self.deltaRotation, 0))
end

function UMG_HomeFurniturePreview_2_C:ChangeScale(scale)
  self.halfHeight = self.unscaledHalfHeight * scale
  self.actorIsolateWorld:SetActorScale3D(UE4.FVector(scale, scale, scale))
  self.actorIsolateWorld:K2_SetActorLocation(self.initLoaction, false, nil, false)
  self.actorIsolateWorld:K2_SetActorRotation(self.firstRotation, false)
  if self.bNeedRotate then
    self:FurnitureRotate(UE4.FRotator(-90, 0, 0))
    self.initRotation = self.actorIsolateWorld:K2_GetActorRotation()
    self.actorInitLocation = self.actorIsolateWorld:K2_GetActorLocation()
  end
  local targetLocation = self.initLoaction + UE4.FVector(0, 0, 1) * self.halfHeight
  local cameraLocation = self.initLoaction + UE4.FVector(1, 0, 0) * 1000 + UE4.FVector(0, 0, 1) * self.halfHeight * 2 + UE4.FVector(0, 0, self.cameraHigh)
  self.camera:K2_SetActorLocation(cameraLocation, false, nil, false)
  local cameraRotation = UE4.UKismetMathLibrary.FindLookAtRotation(cameraLocation, targetLocation)
  self.camera:K2_SetActorRotation(cameraRotation, false)
  self:ChangeRotation(self.cameraHigh, self.deltaRotation)
end

function UMG_HomeFurniturePreview_2_C:ChangeRotation(high, yaw)
  self.cameraHigh = high
  self.deltaRotation = yaw
  self.actorIsolateWorld:K2_SetActorRotation(self.initRotation, false)
  self.actorIsolateWorld:K2_SetActorLocation(self.actorInitLocation, false, nil, false)
  local targetLocation = self.initLoaction + UE4.FVector(0, 0, 1) * self.halfHeight
  local cameraLocation = self.initLoaction + UE4.FVector(1, 0, 0) * 1000 + UE4.FVector(0, 0, 1) * self.halfHeight * 2 + UE4.FVector(0, 0, self.cameraHigh)
  self.camera:K2_SetActorLocation(cameraLocation, false, nil, false)
  local cameraRotation = UE4.UKismetMathLibrary.FindLookAtRotation(cameraLocation, targetLocation)
  self.camera:K2_SetActorRotation(cameraRotation, false)
  self:FurnitureRotate(UE4.FRotator(0, yaw, 0))
end

function UMG_HomeFurniturePreview_2_C:OnDestruct()
  if UE.UObject.IsValid(self.actorIsolateWorld) then
    self.PreviewWorld:DestroyActor(self.actorIsolateWorld)
    self.actorIsolateWorld = nil
  end
  if self.captureComponent then
    self.captureComponent.showOnlyActors:Clear()
  end
  UE4.UNRCQualityLibrary.SwitchNRCGameShadowMode(0)
end

function UMG_HomeFurniturePreview_2_C:HandleTouchMove(position)
  if self._canRotate and self._startLocation then
    local mouseLocation = position
    local deltaLocationX = mouseLocation.X - self._startLocation.X
    local deltaRot = UE4.FRotator(0, -deltaLocationX, 0)
    self:FurnitureRotate(deltaRot)
    self._startLocation = UE4.FVector2D(position.X, position.Y)
  end
end

function UMG_HomeFurniturePreview_2_C:FurnitureRotate(deltaRot)
  if self.actorIsolateWorld then
    local location = self.actorIsolateWorld:K2_GetActorLocation()
    local rotation = self.actorIsolateWorld:K2_GetActorRotation()
    local upVec = UE4.UKismetMathLibrary.GetUpVector(rotation)
    local oldCenter = location + upVec * self.halfHeight
    self.actorIsolateWorld:K2_AddActorWorldRotation(deltaRot, false, nil, false)
    local rotation2 = self.actorIsolateWorld:K2_GetActorRotation()
    local upVec2 = UE4.UKismetMathLibrary.GetUpVector(rotation2)
    local newCenter = location + upVec2 * self.halfHeight
    self.actorIsolateWorld:K2_SetActorLocation(location + oldCenter - newCenter, false, nil, false)
  end
end

function UMG_HomeFurniturePreview_2_C:HandleTouchStart(position)
  self._canRotate = true
  self._startLocation = UE4.FVector2D(position.X, position.Y)
end

function UMG_HomeFurniturePreview_2_C:OnTouchEnded(MyGeometry, InTouchEvent)
  self._canRotate = false
  return UE4.UWidgetBlueprintLibrary.Unhandled()
end

return UMG_HomeFurniturePreview_2_C

local NRCHomePlacementActor_C = Class("NRCHomePlacementActor_C")
local StaticMeshProxy = require("NewRoco/Modules/System/Home/IndoorSandbox/Proxy/StaticMeshProxy")
local SkeletalMeshProxy = require("NewRoco.Modules.System.Home.IndoorSandbox.Proxy.SkeletalMeshProxy")

function NRCHomePlacementActor_C:Ctor()
  self.PropsData = nil
  self.hasPoi = false
  self.bEnableOutlineMat = false
  self:OnConstruct()
end

function NRCHomePlacementActor_C:OnConstruct()
end

function NRCHomePlacementActor_C:ReceiveBeginPlay()
  local AreaData = self.PlaceableAreaData
  local OccupyCell = self.OccupyCell
  self.Length = OccupyCell.X
  self.Width = OccupyCell.Y
  local AreaVolume = AreaData.AreaVolume
  local GenPlaneMin = AreaVolume.Min
  local GenPlaceMax = AreaVolume.Max
  local DiffRange = GenPlaceMax - GenPlaneMin
  if DiffRange.X < 40 or DiffRange.Y < 40 then
  else
    self.GenPlaneMin = GenPlaneMin
    self.GenPlaceMax = GenPlaceMax
  end
  local Components = self:K2_GetComponentsByClass(UE4.UMeshComponent)
  for _, Component in tpairs(Components) do
    local BlueprintClass = Component:GetClass()
    if BlueprintClass:IsChildOf(UE.UNRCHomeStaticMeshComponent) or BlueprintClass:IsChildOf(UE.UStaticMeshComponent) or BlueprintClass:IsChildOf(UE.UNRCStaticMeshComponent) or BlueprintClass:IsChildOf(UE.USkeletalMeshComponent) then
      if not self._MeshComp then
        self._MeshComp = Component
      end
      Component:SetCollisionResponseToChannel(UE4.ECollisionChannel.ECC_Pawn, UE.ECollisionResponse.ECR_Ignore)
    end
  end
  if self.Box then
    self.Box:SetCollisionObjectType(UE.ECollisionChannel.Hit)
  end
  if UE.UObject.IsA(self._MeshComp, UE.UNRCStaticMeshComponent) or UE.UObject.IsA(self._MeshComp, UE.UNRCHomeStaticMeshComponent) then
    self:InternalLoadNrcMesh()
  elseif UE.UObject.IsA(self._MeshComp, UE.UNRCSkeletalMeshComponent) then
    self:InternalLoadNrcSkeletalMesh()
  else
    self.bMeshLoaded = true
  end
  self.DisableMask = 0
end

function NRCHomePlacementActor_C:ReceiveEndPlay()
  if self._StaticMeshProxy then
    self._StaticMeshProxy:OnRelease()
  end
  if self._SkeletalMeshProxy then
    self._SkeletalMeshProxy:OnRelease()
  end
end

function NRCHomePlacementActor_C:InternalLoadNrcMesh()
  self._StaticMeshProxy = StaticMeshProxy()
  self._StaticMeshProxy:OnInit(self, self._MeshComp)
  self._StaticMeshProxy:SetFinishDelegate(FPartial(self.OnMeshLoaded, self))
  self._StaticMeshProxy:StartLoadResources()
end

function NRCHomePlacementActor_C:InternalLoadNrcSkeletalMesh()
  self._SkeletalMeshProxy = SkeletalMeshProxy()
  self._SkeletalMeshProxy:OnInit(self, self._MeshComp)
  self._SkeletalMeshProxy:SetFinishDelegate(FPartial(self.OnMeshLoaded, self))
  self._SkeletalMeshProxy:StartLoadResources()
end

function NRCHomePlacementActor_C:SetCameraCollisionEnabled(bEnabled)
  if not self._MeshComp or not UE.UObject.IsValid(self._MeshComp) then
    return
  end
  if bEnabled then
    self._MeshComp:SetCollisionResponseToChannel(UE.ECollisionChannel.ECC_Camera, UE.ECollisionResponse.ECR_Block)
  else
    self._MeshComp:SetCollisionResponseToChannel(UE.ECollisionChannel.ECC_Camera, UE.ECollisionResponse.ECR_Ignore)
  end
end

function NRCHomePlacementActor_C:OnMeshLoaded()
  self.bMeshLoaded = true
  if self.bPendingOutlineEnable then
    self.bPendingOutlineEnable = nil
    self:SetHighLightOutlineEnabled(true)
  end
end

function NRCHomePlacementActor_C:SetVisible(bVisible, Mask)
  if not self or not UE4.UObject.IsValid(self) then
    return
  end
  Mask = Mask or HomeIndoorSandbox.Enum.PropsDisableMask.Normal
  if bVisible then
    self.DisableMask = self.DisableMask & ~Mask
  else
    self.DisableMask = self.DisableMask | Mask
  end
  if 0 ~= self.DisableMask then
    bVisible = false
  else
    bVisible = true
  end
  self:SetActorHiddenInGame(not bVisible)
end

function NRCHomePlacementActor_C:SetObstacleEnabled(bEnabled)
  if not self._MeshComp then
    return
  end
  if self._bEnabledObstacle == bEnabled then
    return
  end
  self._bEnabledObstacle = bEnabled
  local Channel = UE.UNRCStatics.ConvertToCollisionChannel(UE.EObjectTypeQuery.Character)
  if bEnabled then
    self._MeshComp:SetCollisionResponseToChannel(Channel, UE.ECollisionResponse.ECR_Block)
  else
    self._MeshComp:SetCollisionResponseToChannel(Channel, UE.ECollisionResponse.ECR_Ignore)
  end
  if bEnabled then
    self._MeshComp:SetCollisionResponseToChannel(UE.ECollisionChannel.ECC_Camera, UE.ECollisionResponse.ECR_Block)
  else
    self._MeshComp:SetCollisionResponseToChannel(UE.ECollisionChannel.ECC_Camera, UE.ECollisionResponse.ECR_Ignore)
  end
end

function NRCHomePlacementActor_C:GetGenPlaceMinMaxNoNormalized()
  if not self.GenPlaneMin then
    return
  end
  local WorldTransform = self:Abs_GetTransform()
  local WorldGenPlaneMin = WorldTransform:TransformPositionNoScale(self.GenPlaneMin)
  local WorldGenPlaneMax = WorldTransform:TransformPositionNoScale(self.GenPlaceMax)
  return WorldGenPlaneMin, WorldGenPlaneMax
end

function NRCHomePlacementActor_C:SetHighLightOutlineColor(Color)
  local Mat = HomeIndoorSandbox.World.HomeEditEnv:EnsureGetOutlineHighLightMat()
  Mat:SetVectorParameterValue("CustomOutlineColor", Color)
end

function NRCHomePlacementActor_C:SetHighLightOutlineScale(Scale)
  local Mat = HomeIndoorSandbox.World.HomeEditEnv:EnsureGetOutlineHighLightMat()
  Mat:SetScalarParameterValue("OutlineWidth", Scale or 1.5)
end

function NRCHomePlacementActor_C:SetHighLightOutlineOffset(Offset)
  local Mat = HomeIndoorSandbox.World.HomeEditEnv:EnsureGetOutlineHighLightMat()
  Mat:SetScalarParameterValue("OutlineOffset", Offset or 100)
end

function NRCHomePlacementActor_C:SetHighLightOutlineDistance(Distance)
  local Mat = HomeIndoorSandbox.World.HomeEditEnv:EnsureGetOutlineHighLightMat()
  Mat:SetScalarParameterValue("DistanceUniform", Distance or 0)
end

function NRCHomePlacementActor_C:SetHighLightOutlineEnabled(bEnabled, Mat)
  if not self or not UE4.UObject.IsValid(self) then
    return
  end
  Mat = Mat or HomeIndoorSandbox.World.HomeEditEnv:EnsureGetOutlineHighLightMat()
  if not Mat then
    HomeIndoorSandbox:Ensure(false, "NRCHomePlacementActor_C:SetHighLightOutlineEnabled Failed", bEnabled)
    return
  end
  if not self._MeshComp or not self.bMeshLoaded then
    self.bPendingOutlineEnable = bEnabled
    return
  end
  self.bPendingOutlineEnable = nil
  if bEnabled ~= self.bEnableOutlineMat then
    self.bEnableOutlineMat = bEnabled
    HomeIndoorSandbox:LogDebug("NRCHomePlacementActor_C:SetHighLightOutlineEnabled", bEnabled)
    if bEnabled then
      local NumMaterials = self._MeshComp:GetNumMaterials()
      for Slot = 0, NumMaterials - 1 do
        local DMT = self._MeshComp:CreateAndSetMaterialInstanceDynamic(Slot)
        if not DMT then
          HomeIndoorSandbox:Ensure(false, "cannot found material", self:GetFullName())
          return
        end
        local AdditionalMaterials = DMT.AdditionalMaterials
        local Index = AdditionalMaterials:Add(Mat)
        HomeIndoorSandbox:LogDebug("NRCHomePlacementActor_C:SetHighLightOutlineEnabled Add", Index, "Slot", Slot)
        assert(DMT.AdditionalMaterials:Get(Index) == Mat)
        self._MeshComp:SetMaterial(Slot, DMT)
      end
    else
      local NumMaterials = self._MeshComp:GetNumMaterials()
      for Slot = 0, NumMaterials - 1 do
        local DMT = self._MeshComp:CreateAndSetMaterialInstanceDynamic(Slot)
        if not DMT then
          HomeIndoorSandbox:Ensure(false, "cannot found material", self:GetFullName())
          return
        end
        local AdditionalMaterials = DMT.AdditionalMaterials
        for i, v in tpairs(AdditionalMaterials) do
          if v == Mat then
            AdditionalMaterials:Remove(i)
            HomeIndoorSandbox:LogDebug("NRCHomePlacementActor_C:SetHighLightOutlineEnabled Remove", i, "Slot", Slot)
            break
          end
        end
        self._MeshComp:SetMaterial(Slot, DMT.Parent)
      end
    end
  end
end

function NRCHomePlacementActor_C:GetLocalGenPlaneMinMax()
  return self.GenPlaneMin, self.GenPlaceMax
end

function NRCHomePlacementActor_C:GetGenPlaneHeight()
  if self.GenPlaneMin then
    return self:GetHalfHeight() + self.GenPlaneMin.Z
  else
    return self:GetHalfHeight() * 2
  end
end

function NRCHomePlacementActor_C:GetHalfHeight()
  return 0
end

function NRCHomePlacementActor_C:SetIsSelected(bSelected, bNoUseSpringArm)
  if not self or not UE4.UObject.IsValid(self) then
    return
  end
  HomeIndoorSandbox:LogDebug("SetIsSelected", self, bSelected, bNoUseSpringArm)
  if self._bSelected ~= bSelected then
    self._bSelected = bSelected
    if bSelected then
      self:K2_AddActorLocalOffset(HomeIndoorSandbox.Utils.SELECT_LOCAL_OFFSET, false, nil, false)
    else
      self:OnPreMove()
      self:K2_AddActorLocalOffset(-HomeIndoorSandbox.Utils.SELECT_LOCAL_OFFSET, false, nil, false)
      self:OnPostMove()
      _G.NRCAudioManager:PlaySound2DAuto(1220002054, "NRCHomePlacementActor_C:SetIsSelected")
    end
    self:SetHighLightOutlineEnabled(bSelected)
  end
  if not bNoUseSpringArm then
    self:UseSpringArm(bSelected)
  end
end

function NRCHomePlacementActor_C:IsPropsSelected()
  return self._bSelected or false
end

function NRCHomePlacementActor_C:GetSpringArm()
  if not self or not UE4.UObject.IsValid(self) then
    return
  end
  if self._SpringArm then
    return self._SpringArm
  end
  self._SpringArm = self:AddComponentByClass(UE.USpringArmComponent, false, UE.FTransform(), false)
  self._SpringArm.TargetArmLength = 0
  self._SpringArm.bDoCollisionTest = 0
  self._SpringArm.bUsePawnControlRotation = false
  self._SpringArm.bEnableCameraLag = false
  self._SpringArm.bEnableCameraRotationLag = false
  self._SpringArm.bDrawDebugLagMarkers = HomeIndoorSandbox.Utils.EnableDebugDraw
  self._SpringArm.CameraLagSpeed = HomeIndoorSandbox.Utils.CELL_SIZE / 2
  self._SpringArm.CameraRotationLagSpeed = HomeIndoorSandbox.Utils.ROTATOR_ANGLE_ONCE / 2
  return self._SpringArm
end

function NRCHomePlacementActor_C:UseSpringArm(bUse)
  if bUse == self._bUseSpringArm then
    return
  end
  self._bUseSpringArm = bUse
  local MeshRoot = self.MeshRoot
  local Arm = self:GetSpringArm()
  if not Arm then
    return
  end
  if bUse then
    MeshRoot:K2_AttachToComponent(Arm, nil, UE.EAttachmentRule.KeepRelative, UE.EAttachmentRule.KeepRelative, UE.EAttachmentRule.KeepRelative, true)
  else
    self:OnPreMove()
    MeshRoot:K2_AttachToComponent(self:K2_GetRootComponent(), nil, UE.EAttachmentRule.KeepRelative, UE.EAttachmentRule.KeepRelative, UE.EAttachmentRule.KeepRelative, true)
    self:OnPostMove()
  end
  if self._DelaySpringDisableHandle then
    DelayManager:CancelDelayById(self._DelaySpringDisableHandle)
    self._DelaySpringDisableHandle = nil
  end
  if not bUse then
    Arm.bEnableCameraLag = false
    Arm.bEnableCameraRotationLag = false
    self._DelaySpringDisableHandle = DelayManager:DelayFrames(1, function()
      self._DelaySpringDisableHandle = nil
      if self:IsValid() then
        Arm:SetComponentTickEnabled(false)
      end
    end)
  else
    Arm.bEnableCameraLag = false
    Arm.bEnableCameraRotationLag = false
    Arm:SetComponentTickEnabled(true)
    self._DelaySpringDisableHandle = DelayManager:DelayFrames(1, function()
      self._DelaySpringDisableHandle = nil
      if self:IsValid() then
        Arm.bEnableCameraLag = true
        Arm.bEnableCameraRotationLag = true
      end
    end)
  end
  HomeIndoorSandbox:LogInfo("UseSpringArm", self:GetName(), bUse)
  local ChildActors = self.PropsData and self.PropsData:ResolveSubPropsActorArray()
  if ChildActors then
    for _, Child in tpairs(ChildActors) do
      if Child.PropsData then
        if bUse then
          Child:K2_GetRootComponent():K2_AttachToComponent(Arm, nil, UE.EAttachmentRule.KeepRelative, UE.EAttachmentRule.KeepRelative, UE.EAttachmentRule.KeepRelative, true)
          HomeIndoorSandbox:Ensure(Child:GetAttachParentActor() == self, "logical error")
        else
          Child:K2_GetRootComponent():K2_AttachToComponent(self:K2_GetRootComponent(), nil, UE.EAttachmentRule.KeepRelative, UE.EAttachmentRule.KeepRelative, UE.EAttachmentRule.KeepRelative, true)
        end
      end
    end
  end
end

function NRCHomePlacementActor_C:OnPreMove()
  if self.Box then
    self.Box.bUpdateNavigationData = true
  end
end

function NRCHomePlacementActor_C:OnPostMove()
  if self.Box then
    self.Box.bUpdateNavigationData = false
  end
end

function NRCHomePlacementActor_C:OnNpcChanged(Npc, bReady)
end

function NRCHomePlacementActor_C:K2_SetActorRotation(NewRotation, bTeleportPhysics)
  if self.PropsData then
    return
  end
  HomeIndoorSandbox:LogDebug("NRCHomePlacementActor_C:K2_SetActorRotation", NewRotation)
  self.Overridden.K2_SetActorRotation(self, NewRotation, bTeleportPhysics)
end

function NRCHomePlacementActor_C:K2_SetActorLocationAndRotation(NewLocation, NewRotation, bSweep, SweepHitResult, bTeleport)
  if self.PropsData then
    return
  end
  HomeIndoorSandbox:LogDebug("NRCHomePlacementActor_C:K2_SetActorLocationAndRotation", NewRotation)
  self.Overridden.K2_SetActorLocationAndRotation(self, NewLocation, NewRotation, bSweep, SweepHitResult, bTeleport)
end

function NRCHomePlacementActor_C:Abs_K2_SetActorLocationAndRotation(NewLocation, NewRotation, bSweep, SweepHitResult, bTeleport)
  if self.PropsData then
    return
  end
  HomeIndoorSandbox:LogDebug("NRCHomePlacementActor_C:Abs_K2_SetActorLocationAndRotation", NewRotation)
  self.Overridden.Abs_K2_SetActorLocationAndRotation(self, NewLocation, NewRotation, bSweep, SweepHitResult, bTeleport)
end

function NRCHomePlacementActor_C:K2_SetActorLocationAndRotation(NewLocation, NewRotation, bSweep, SweepHitResult, bTeleport)
  if self.PropsData then
    return
  end
  HomeIndoorSandbox:LogDebug("NRCHomePlacementActor_C:K2_SetActorLocationAndRotation", NewRotation)
  self.Overridden.K2_SetActorLocationAndRotation(self, NewLocation, NewRotation, bSweep, SweepHitResult, bTeleport)
end

function NRCHomePlacementActor_C:Abs_K2_SetActorLocation_WithoutHit(NewLocation, bSweep, bTeleport)
  if self.PropsData then
    return
  end
  HomeIndoorSandbox:LogDebug("NRCHomePlacementActor_C:Abs_K2_SetActorLocation_WithoutHit", NewLocation)
  self.Overridden.Abs_K2_SetActorLocation_WithoutHit(self, NewLocation, bSweep, bTeleport)
end

function NRCHomePlacementActor_C:SetVisibilityChannel(Response)
  if self._MeshComp and UE.UObject.IsValid(self._MeshComp) then
    self._MeshComp:SetCollisionResponseToChannel(UE.ECollisionChannel.ECC_Visibility, Response)
  end
end

return NRCHomePlacementActor_C

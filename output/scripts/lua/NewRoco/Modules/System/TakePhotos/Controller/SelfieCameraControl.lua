local SelfieCameraResource = require("NewRoco.Modules.System.TakePhotos.Helper.SelfieCameraResource")
local TakePhotosUtils = require("NewRoco/Modules/System/TakePhotos/TakePhotosUtils")
local TakePhotosModuleEvent = require("NewRoco.Modules.System.TakePhotos.TakePhotosModuleEvent")
local SelfieCameraControl = Class()

function SelfieCameraControl:Ctor(TakePhotosModeSelfie)
  self.Mode = TakePhotosModeSelfie
  self.TraceObjectTypes = {
    UE.EObjectTypeQuery.WorldDynamic,
    UE.EObjectTypeQuery.WorldStatic,
    UE.EObjectTypeQuery.Character,
    UE.EObjectTypeQuery.Visibility,
    UE.EObjectTypeQuery.WaterSurface,
    UE.EObjectTypeQuery.Pawn
  }
  self.DeltaToleranceVec = UE.FVector(0, 0, 1)
  self.AttachParams = nil
  self.SelfieCameraResource = SelfieCameraResource()
  self.SelfieCameraResource:ConditionalLoad()
  self.SweepHitResult = UE.FHitResult()
  self.Overlaps = {}
  self.OverlapCache = UE4.TArray(UE.AActor)
  self.CacheHasSpecialHats = false
  self.CacheWardrobeIndex = nil
  self.SpecialHatTypes = {
    [13] = true,
    [27] = true,
    [28] = true
  }
  self.bIsPcMode = _G.UE4Helper.IsPCMode()
end

function SelfieCameraControl:GatherAttachParamsConfig(Rider)
  local TPGNum = TakePhotosEnum.TPGlobalNum
  local AttachParamsConfigs = {
    HorizontalViewOffset = DEBUG_SELFIE_VIEW_H or TPGNum("takephoto_myself_initial_HorizontalViewOffset", 30),
    HorizontalCamOffset = DEBUG_SELFIE_CAM_H or TPGNum("takephoto_myself_initial_HorizontalCamOffset", 0),
    DistanceViewOffset = DEBUG_SELFIE_CAM_DIS or TPGNum("takephoto_myself_initial_DistanceViewOffset", 75),
    InitHeightOffset = DEBUG_SELFIE_CAM_INIT_HEIGHT or TPGNum("takephoto_myself_initial_HeightOffset", 50),
    ViewHeightOffset = DEBUG_SELFIE_VIEW_HEIGHT or TPGNum("takephoto_myself_initial_ViewHeightOffset", 50),
    HandOffsetX = DEBUG_SELFIE_HAND_OFFSET_X or TPGNum("takephoto_myself_initial_HandOffsetX", -25),
    HandOffsetY = DEBUG_SELFIE_HAND_OFFSET_Y or TPGNum("takephoto_myself_initial_HandOffsetY", 50),
    HandOffsetZ = DEBUG_SELFIE_HAND_OFFSET_Z or TPGNum("takephoto_myself_initial_HandOffsetZ", 0),
    MiniCameraHeight = DEBUG_SELFIE_CAMERA_MINI_HEIGHT or TPGNum("takephoto_myself_MiniCamerHeight", -20),
    MaxiCameraHeight = DEBUG_SELFIE_CAMERA_MAXI_HEIGHT or TPGNum("takephoto_myself_MaxiCamerHeight", 70)
  }
  if Rider then
    local ScenePet = self.Player:GetRidePetLua()
    local PetBaseId = ScenePet.config.id
    local RideConf = _G.DataConfigManager:GetAllRidePet(PetBaseId)
    if _G.TakePhotoEditorTools and _G.TakePhotoEditorTools.Get() then
      local Tls = _G.TakePhotoEditorTools.Get()
      local view_offset_h = Tls:GetSelfieData("view_offset_h")
      local view_offset_v = Tls:GetSelfieData("view_offset_v")
      local cam_offset_h = Tls:GetSelfieData("cam_offset_h")
      local cam_offset_d = Tls:GetSelfieData("cam_offset_d")
      local cam_offset_l = Tls:GetSelfieData("cam_offset_l")
      local cam_min_l = Tls:GetSelfieData("cam_min_l")
      local cam_max_l = Tls:GetSelfieData("cam_max_l")
      AttachParamsConfigs.HorizontalViewOffset = view_offset_h
      AttachParamsConfigs.ViewHeightOffset = view_offset_v
      AttachParamsConfigs.HorizontalCamOffset = cam_offset_h
      AttachParamsConfigs.InitHeightOffset = cam_offset_l
      AttachParamsConfigs.DistanceViewOffset = cam_offset_d
      AttachParamsConfigs.MiniCameraHeight = cam_min_l
      AttachParamsConfigs.MaxiCameraHeight = cam_max_l
    else
      local selfie_takephoto_params = RideConf.selfie_takephoto_params or ""
      local nums = string.split(selfie_takephoto_params, ";")
      for i, num in ipairs(nums) do
        nums[i] = tonumber(num) or 0
      end
      local view_offset_h = nums[1] or 0
      local view_offset_v = nums[2] or 0
      local cam_offset_h = nums[3] or 0
      local cam_offset_d = nums[4] or 200
      local cam_offset_l = nums[5] or 0
      local cam_min_l = nums[6] or 0
      local cam_max_l = nums[7] or 150
      AttachParamsConfigs.HorizontalViewOffset = view_offset_h
      AttachParamsConfigs.ViewHeightOffset = view_offset_v
      AttachParamsConfigs.HorizontalCamOffset = cam_offset_h
      AttachParamsConfigs.InitHeightOffset = cam_offset_l
      AttachParamsConfigs.DistanceViewOffset = cam_offset_d
      AttachParamsConfigs.MiniCameraHeight = cam_min_l
      AttachParamsConfigs.MaxiCameraHeight = cam_max_l
    end
  end
  return AttachParamsConfigs
end

function SelfieCameraControl:OnSelfieConfigChangedEd()
  if not self.AttachParams then
    return
  end
  if self.AttachParams.b2PRider then
    self:Apply2PRiderConfig(self.AttachParams)
    return
  end
  local AttachParamsConfigs = self.AttachParams.Config
  local AttachParams = self.AttachParams
  local Tls = _G.TakePhotoEditorTools.Get()
  local view_offset_h = Tls:GetSelfieData("view_offset_h")
  local view_offset_v = Tls:GetSelfieData("view_offset_v")
  local cam_offset_h = Tls:GetSelfieData("cam_offset_h")
  local cam_offset_d = Tls:GetSelfieData("cam_offset_d")
  local cam_offset_l = Tls:GetSelfieData("cam_offset_l")
  local cam_min_l = Tls:GetSelfieData("cam_min_l")
  local cam_max_l = Tls:GetSelfieData("cam_max_l")
  AttachParamsConfigs.HorizontalViewOffset = view_offset_h
  AttachParamsConfigs.ViewHeightOffset = view_offset_v
  AttachParamsConfigs.HorizontalCamOffset = cam_offset_h
  AttachParamsConfigs.InitHeightOffset = cam_offset_l
  AttachParamsConfigs.DistanceViewOffset = cam_offset_d
  AttachParamsConfigs.MiniCameraHeight = cam_min_l
  AttachParamsConfigs.MaxiCameraHeight = cam_max_l
  local HorizontalViewOffset = AttachParamsConfigs.HorizontalViewOffset
  local ViewHeightOffset = AttachParamsConfigs.ViewHeightOffset
  local DistanceViewOffset = AttachParamsConfigs.DistanceViewOffset
  local HorizontalCamOffset = AttachParamsConfigs.HorizontalCamOffset
  local InitHeightOffset = AttachParamsConfigs.InitHeightOffset
  local DirFactor = AttachParams.bReadOnlyUsingRightHand and -1 or 1
  local ViewOffset = UE.FVector(0, HorizontalViewOffset * DirFactor, ViewHeightOffset)
  local LocationOffset = UE.FVector(DistanceViewOffset, HorizontalCamOffset * DirFactor, InitHeightOffset)
  local Forward = ViewOffset - LocationOffset
  self.AttachParams.ReadOnlyViewPointOffset = ViewOffset
  self.AttachParams.ReadOnlyRelativeTransform = UE.FTransform(Forward:ToQuat(), LocationOffset, FVectorOne)
  if self.DesiredHeight then
    self.ElapsedInputHeight = InitHeightOffset - self.DesiredHeight
  end
  Log.Debug("SelfieCameraControl Editor Rotation:", self.AttachParams.ReadOnlyRelativeTransform.Rotation:ToRotator())
end

function SelfieCameraControl:OnTick(Dt)
  if not self.AttachParams then
    return
  end
  if self.bPendingExit then
    self:Interrupt("PendingExit")
    return
  end
  if self.AttachParams.b2PRider then
    local AttachedOwner = self:GatherAttachedOwner()
    local CurrentAttachedOwner = self.AttachParams.AttachedOwner
    if AttachedOwner ~= CurrentAttachedOwner then
      self.AttachParams = self:GatherAttachParams()
    end
    if not self.AttachParams then
      self:Interrupt("cannot found attach params", AttachedOwner)
      return
    end
    if self.AttachParams.b2PRider then
      self:Tick2pRider(Dt)
      return
    else
      self.SelfieCameraResource.OnSpawned:Clear()
      self.SelfieCameraResource.OnSpawned:Add(self, self.OnCameraReady)
      self.SelfieCameraResource:ConditionalSpawn(self.AttachParams.ReadOnlyWorldTransform)
      self:InternalAttachComponent()
    end
    return
  end
  if not self.AttachParams.AttachedOwner then
    return
  end
  local Camera = self.SelfieCameraResource:GetCamera()
  if not Camera or not UE.UObject.IsValid(Camera) then
    return
  end
  local bReadOnlyUsingRightHand = self.AttachParams.bReadOnlyUsingRightHand
  local AttachedOwner = self:GatherAttachedOwner()
  local CurrentAttachedOwner = self.AttachParams.AttachedOwner
  if AttachedOwner ~= CurrentAttachedOwner then
    self:InternalClearInput()
    self:InternalDetachComponent()
    self.AttachParams = self:GatherAttachParams()
    if not self.AttachParams then
      self:Interrupt("cannot found attach params", AttachedOwner)
      return
    end
    if self.AttachParams.b2PRider then
      return
    end
    if not self:InternalAttachComponent() then
      self:Interrupt("attach failed")
      return
    end
  else
    local CurrentAttachedRightHand = self.AttachParams.bReadOnlyUsingRightHand
    local DesiredRightHand = self:GatherAttachRightHand()
    if CurrentAttachedRightHand ~= DesiredRightHand then
      local DesiredHeight = self.DesiredHeight
      self:InternalClearInput()
      self:InternalAdjustHand(DesiredHeight)
    end
  end
  if bReadOnlyUsingRightHand ~= self.AttachParams.bReadOnlyUsingRightHand then
    self.bHandActionDirty = true
  end
  local curCamActor = self.Player.ueController:GetViewTarget()
  if curCamActor ~= Camera then
    Log.Warning("[TakePhoto] camera changed, exit take photo selfie")
    NRCModuleManager:DoCmd(TakePhotosModuleCmd.ExitTakePhotos)
    return
  end
  local Rider = self.AttachParams.Rider
  local bRiderMoving = false
  local bLastRiderMoving = self.AttachParams.bLastRiderMoving or false
  if Rider then
    local Component = Rider:GetMovementComponent()
    local Velocity = Component.Velocity
    local NoInput = math.abs(Velocity.X) < 2 and math.abs(Velocity.Y) < 2
    bRiderMoving = not NoInput
    if Component:GetLastInputVector():Size() > 0 then
      bRiderMoving = true
    end
  end
  self.AttachParams.bRiderMoving = bRiderMoving
  if bRiderMoving then
    if not bLastRiderMoving then
      local CameraTransform = Camera:Abs_GetTransform()
      Camera:K2_GetRootComponent():SetAbsolute(true, true, false)
      Camera:Abs_K2_SetActorTransform_WithoutHit(CameraTransform, false, false)
      local WorldTransform = Rider:GetTransform()
      local Rotation = self.AttachParams.RiderDesiredRotator or self.AttachParams.Rider:K2_GetActorRotation()
      local Location = self.AttachParams.Rider:K2_GetActorLocation()
      local RiderTransform = UE.FTransform(Rotation:ToQuat(), Location, WorldTransform.Scale3D)
      self.AttachParams.RiderMovingTransform = RiderTransform
    end
    self:TickControlByRiderMoving(Dt, Camera)
  else
    if bLastRiderMoving then
      Camera:K2_GetRootComponent():SetAbsolute(false, false, false)
      local RiderMovingTransform = self.AttachParams.RiderMovingTransform
      self.Player:SetActorRotation(RiderMovingTransform.Rotation:ToRotator())
      self.AttachParams.RiderMovingTransform = nil
      self.AttachParams.RiderDesiredRotator = RiderMovingTransform.Rotation:ToRotator()
    end
    self:TickControlByNoRiderMoving(Dt, Camera)
    if self.AttachParams.Rider then
      self.AttachParams.RiderDesiredRotator = self.AttachParams.Rider:K2_GetActorRotation()
    end
  end
  self:InternalUpdateOverlapOpacity(Camera)
  self.AttachParams.bLastRiderMoving = bRiderMoving
  UE.UNRCStatics.ForceTickCamera(Dt)
end

function SelfieCameraControl:TickControlByNoRiderMoving(Dt, Camera)
  if math.abs(self.ElapsedInputYaw) > 0.01 then
    local DeltaYaw = self:Lerp(0, self.ElapsedInputYaw, Dt)
    self.ElapsedInputYaw = self.ElapsedInputYaw - DeltaYaw
    self.AttachParams.AttachedOwner:K2_AddActorWorldRotation(UE.FRotator(0, DeltaYaw, 0), false, nil, false)
    local Rotation = self.AttachParams.AttachedOwner:K2_GetActorRotation()
    self.Player:SetActorRotation(Rotation)
  end
  if math.abs(self.ElapsedInputHeight) > 0.01 then
    local DeltaHeight = self:Lerp(0, self.ElapsedInputHeight, Dt)
    self.DesiredHeight = self.DesiredHeight + DeltaHeight
    self.DesiredHeight = math.max(math.min(self.DesiredHeight, self.AttachParams.Config.MaxiCameraHeight), self.AttachParams.Config.MiniCameraHeight)
    self.ElapsedInputHeight = self.ElapsedInputHeight - DeltaHeight
  end
  local OwnerTransform = self.AttachParams.AttachedOwner:Abs_GetTransform()
  local LookAtRot = self:InternalSweepAdjustCamera(Camera)
  if not self.AttachParams.Rider then
    local HandWorldPoint = OwnerTransform:TransformVector(self.AttachParams.ReadOnlyHandLocalOffset)
    self.Player.viewObj.HandIkTargetActorOffset = HandWorldPoint
  else
    local Movement = self.AttachParams.Rider:GetMovementComponent()
    Movement.Velocity.X = 0
    Movement.Velocity.Y = 0
  end
  self.Player.ueController:SetControlRotation(LookAtRot)
end

function SelfieCameraControl:TickControlByRiderMoving(Dt, Camera)
  if math.abs(self.ElapsedInputYaw) > 0.01 then
    local DeltaYaw = self:Lerp(0, self.ElapsedInputYaw, Dt)
    self.ElapsedInputYaw = self.ElapsedInputYaw - DeltaYaw
    local Current = self.AttachParams.RiderMovingTransform.Rotation
    self.AttachParams.RiderMovingTransform.Rotation = Current * UE.FRotator(0, DeltaYaw, 0):ToQuat()
  end
  if math.abs(self.ElapsedInputHeight) > 0.01 then
    local DeltaHeight = self:Lerp(0, self.ElapsedInputHeight, Dt)
    self.DesiredHeight = self.DesiredHeight + DeltaHeight
    self.DesiredHeight = math.max(math.min(self.DesiredHeight, self.AttachParams.Config.MaxiCameraHeight), self.AttachParams.Config.MiniCameraHeight)
    self.ElapsedInputHeight = self.ElapsedInputHeight - DeltaHeight
  end
  local Current = self.AttachParams.RiderMovingTransform.Translation
  local Target = self.AttachParams.Rider:K2_GetActorLocation()
  local Desired = Target
  self.AttachParams.RiderMovingTransform.Translation = Desired
  local LookAt = self:InternalSweepAdjustCamera(Camera)
  self.Player.ueController:SetControlRotation(LookAt)
end

function SelfieCameraControl:GetOwnerWorldTrans()
  if self.AttachParams.bRiderMoving then
    return self.AttachParams.RiderMovingTransform
  end
  local RootWorldTransform = self.AttachParams.AttachedOwner:GetTransform()
  if self.AttachParams.Rider then
    return RootWorldTransform
  end
  local Owner = self.AttachParams.AttachedOwner
  Owner.Mesh:GetSocketTransform()
  local HeadMeshLoc = Owner.Mesh:GetSocketTransform("locator_head", UE.ERelativeTransformSpace.RTS_Component).Translation
  local HeadOffsetZ = HeadMeshLoc.Z - 138.88
  RootWorldTransform.Translation = RootWorldTransform.Translation + UE.FVector(0, 0, HeadOffsetZ)
  return RootWorldTransform
end

function SelfieCameraControl:GetCameraDistance(Camera)
  if self.AttachParams.bRiderMoving then
    return self.AttachParams.RiderMovingTransform:InverseTransformPosition(Camera:K2_GetActorLocation()).X
  else
    return Camera:K2_GetRootComponent():GetRelativeTransform().Translation.X
  end
end

function SelfieCameraControl:InternalSweepAdjustCamera(Camera)
  local Channel = UE.ECollisionChannel.ECC_Camera
  local OwnerWorldTrans = self:GetOwnerWorldTrans()
  local AttachRelativeOffset = self.AttachParams.ReadOnlyRelativeTransform.Translation
  local DesiredRelativeTransform = UE.FTransform(self.AttachParams.ReadOnlyRelativeTransform.Rotation, UE.FVector(AttachRelativeOffset.X, AttachRelativeOffset.Y, self.DesiredHeight), self.AttachParams.ReadOnlyRelativeTransform.Scale3D)
  local DesiredCameraWorldTransform = UE.UKismetMathLibrary.ComposeTransforms(DesiredRelativeTransform, OwnerWorldTrans)
  local DesiredCameraWorldLocation = DesiredCameraWorldTransform.Translation
  local WorldAimOriginal = OwnerWorldTrans:TransformPosition(UE.FVector(0, 0, self.AttachParams.ReadOnlyViewPointOffset.Z))
  UE.UNRCStatics.SphereSweepSingleByChannel(self.World, self.SweepHitResult, WorldAimOriginal, DesiredCameraWorldLocation, 20, Channel, {
    Camera,
    self.Player.viewObj,
    self.AttachParams.AttachedOwner
  })
  if self.SweepHitResult.bBlockingHit then
    DesiredCameraWorldLocation = UE.FVector(self.SweepHitResult.Location.X, self.SweepHitResult.Location.Y, self.SweepHitResult.Location.Z)
    Log.Debug("SelfieCameraControl:SweepHitResult:", self.SweepHitResult.Component:GetName())
    if self:GetCameraDistance(Camera) < 0.01 then
      self.bPendingExit = true
    end
  end
  DesiredCameraWorldTransform.Translation = DesiredCameraWorldLocation
  Camera:K2_SetActorTransform(DesiredCameraWorldTransform, false, nil, false)
  local Distance = self:GetCameraDistance(Camera)
  local Scale = Distance / self.AttachParams.ReadOnlyRelativeTransform.Translation.X
  local CameraComponent = Camera:GetComponentByClass(UE.UCameraComponent)
  local AimPoint = UE.FVector(self.AttachParams.ReadOnlyViewPointOffset.X * Scale, self.AttachParams.ReadOnlyViewPointOffset.Y * Scale, self.AttachParams.ReadOnlyViewPointOffset.Z)
  AimPoint = OwnerWorldTrans:TransformPosition(AimPoint)
  local LookAt = AimPoint - DesiredCameraWorldLocation
  LookAt:Normalize()
  local LookAtRot = UE.UKismetMathLibrary.MakeRotFromXZ(LookAt, FVectorUp)
  CameraComponent:K2_SetWorldRotation(LookAtRot, false, nil, false)
  CameraComponent:SetFieldOfView(self.PlayerCameraManager.FOV)
  return LookAtRot
end

function SelfieCameraControl:GetPlayerHideDistance()
  local current_wardrobe_index = _G.DataModelMgr.PlayerDataModel:GetPlayerFashionInfo().current_wardrobe_index or 0
  local wardrobeIndex = current_wardrobe_index + 1
  local wardrobe_data = _G.DataModelMgr.PlayerDataModel:GetPlayerFashionInfo().wardrobe_data
  if wardrobe_data and wardrobeIndex ~= self.CacheWardrobeIndex then
    self.CacheWardrobeIndex = wardrobeIndex
    self.CacheHasSpecialHats = false
    local fashion = wardrobe_data[wardrobeIndex]
    if fashion and fashion.wearing_item then
      for i, item in ipairs(fashion.wearing_item) do
        if item and 0 ~= item.wearing_item_id then
          local fashionItem = _G.DataConfigManager:GetFashionItemConf(item.wearing_item_id)
          if fashionItem.type == Enum.FashionLabelType.FLT_HATS then
            local Type = item.wearing_item_id // 100000 % 100
            if self.SpecialHatTypes[Type] then
              self.CacheHasSpecialHats = true
              break
            end
          end
        end
      end
    end
  end
  local bHasSpecialHats = self.CacheHasSpecialHats
  if bHasSpecialHats then
    return DEBUG_SAFE_SELFIE_LEN or 51
  end
  return 40
end

local ATTACHED_ACTORS = UE.TArray(UE.AActor)

function SelfieCameraControl:InternalUpdateOverlapOpacity(Camera)
  for Overlap, _ in pairs(self.Overlaps) do
    self.Overlaps[Overlap] = 0
  end
  local DistanceToCamera = 0
  if self.AttachParams.Rider then
    DistanceToCamera = self:GetCameraDistance(Camera)
  else
    local HeadMeshLoc = self.Player.viewObj.Mesh:GetSocketTransform("locator_head", UE.ERelativeTransformSpace.RTS_World).Translation
    local CameraLoc = Camera:K2_GetActorLocation()
    DistanceToCamera = (HeadMeshLoc - CameraLoc):Size()
  end
  if DistanceToCamera < self:GetPlayerHideDistance() then
    self.Player.viewObj:SetFadeAlpha(1)
  else
    self.Player.viewObj:SetFadeAlpha(0)
  end
  local ObjectTypes = {
    UE.EObjectTypeQuery.Character,
    UE.EObjectTypeQuery.Pawn
  }
  local CachedResults = self.OverlapCache
  local Success = UE.UNRCStatics.SphereOverlapActors(self.World, Camera:K2_GetActorLocation(), 19, ObjectTypes, {
    self.Player.viewObj,
    Camera
  }, CachedResults)
  if not Success then
    CachedResults:Clear()
  end
  for i, Overlap in tpairs(CachedResults) do
    self.Overlaps[Overlap] = 1
    local WorldPlayer = Overlap:GetAttachParentActor()
    if WorldPlayer and WorldPlayer.sceneCharacter and WorldPlayer.sceneCharacter.isLocal == false and WorldPlayer.SetFadeAlpha then
      self.Overlaps[WorldPlayer] = 1
      WorldPlayer:GetAttachedActors(ATTACHED_ACTORS, true)
      for _, Child in pairs(ATTACHED_ACTORS) do
        self.Overlaps[Child] = 1
      end
      ATTACHED_ACTORS:Resize(0)
    else
      WorldPlayer = Overlap
      if WorldPlayer.sceneCharacter and WorldPlayer.sceneCharacter.isLocal == false then
        WorldPlayer:GetAttachedActors(ATTACHED_ACTORS, true)
        for _, Child in pairs(ATTACHED_ACTORS) do
          self.Overlaps[Child] = 1
        end
        ATTACHED_ACTORS:Resize(0)
      end
    end
  end
  for Overlap, Alpha in pairs(self.Overlaps) do
    self:InternalEnabledAlpha(Overlap, Alpha)
    if 0 == Alpha then
      self.Overlaps[Overlap] = nil
    end
  end
end

function SelfieCameraControl:InternalEnabledAlpha(Overlap, Alpha)
  if not UE.UObject.IsValid(Overlap) then
    return
  end
  local bVisible = 0 == Alpha
  if Overlap.SetFadeAlpha then
    Overlap:SetFadeAlpha(Alpha)
  else
    local SceneCharacter = Overlap.sceneCharacter
    if SceneCharacter then
      if SceneCharacter.SetVisibleForTakePhoto then
        SceneCharacter:SetVisibleForTakePhoto(bVisible)
      end
    elseif Overlap.SetMeshAlpha then
      Overlap:SetMeshAlpha(Alpha)
    end
  end
end

function SelfieCameraControl:ResetOverlaps()
  if self.Player.viewObj and UE.UObject.IsValid(self.Player.viewObj) then
    self.Player.viewObj:SetFadeAlpha(0)
  end
  for Overlap, _ in pairs(self.Overlaps) do
    self:InternalEnabledAlpha(Overlap, 0)
  end
  self.Overlaps = {}
end

function SelfieCameraControl:InternalClearInput()
  self.ElapsedInputYaw = 0
  self.ElapsedInputHeight = 0
  self.DesiredHeight = 0
end

function SelfieCameraControl:Lerp(Prev, Target, DeltaTime)
  if DeltaTime > 0.0166 then
    local FovSpeed = (Target - Prev) / DeltaTime
    local LerpTarget = Prev
    local RemainingTime = DeltaTime
    while RemainingTime > 1.0E-4 do
      local LerpDt = math.min(RemainingTime, 0.0166)
      LerpTarget = LerpTarget + FovSpeed * LerpDt
      RemainingTime = RemainingTime - LerpDt
      local f = math.clamp(LerpDt * 10, 0, 1)
      Target = LerpTarget * f + (1 - f) * Prev
      Prev = Target
    end
  else
    local f = math.clamp(DeltaTime * 10, 0, 1)
    Target = Target * f + (1 - f) * Prev
  end
  return Target
end

function SelfieCameraControl:OnToggleMouseMoveStatus(bMoving)
  if self.AttachParams and self.AttachParams.b2PRider then
    Log.Debug("OnToggleMouseMoveStatus", bMoving)
    if bMoving then
      self.Player.ueController.BP_RocoCameraControlComponent:OnInputTouchStart()
    else
      self.Player.ueController.BP_RocoCameraControlComponent:OnInputTouchEnd()
    end
  end
end

function SelfieCameraControl:InputTurn(InputDir, RawInput)
  if self.AttachParams and self.AttachParams.b2PRider and self.bIsPcMode then
    self.Player.ueController:MouseMove(UE.FVector(RawInput.X * 4, RawInput.Y * 1.7, 0))
    return
  end
  local Camera = self.SelfieCameraResource:GetCamera()
  if not Camera or not UE.UObject.IsValid(Camera) then
    return
  end
  if not self.AttachParams or not self.AttachParams.AttachedOwner then
    return
  end
  local DeltaYaw = InputDir.X * 3.5
  self.ElapsedInputYaw = self.ElapsedInputYaw + DeltaYaw
  local DeltaHeight = InputDir.Y * 7
  self.ElapsedInputHeight = self.ElapsedInputHeight + DeltaHeight
end

function SelfieCameraControl:ResetCameraView()
  if not self.AttachParams then
    return
  end
  if self.AttachParams.b2PRider then
    self:Apply2PRiderConfig(self.AttachParams)
    return
  end
  local Camera = self.SelfieCameraResource:GetCamera()
  if not Camera or not UE.UObject.IsValid(Camera) then
    return
  end
  self:InternalClearInput()
  Camera:K2_SetActorRelativeTransform(self.AttachParams.ReadOnlyRelativeTransform, false, nil, true)
  TakePhotosUtils.ResetSelfieCameraView(Camera)
  self.DesiredHeight = self.AttachParams.ReadOnlyRelativeTransform.Translation.Z
  local OwnerTransform = self.AttachParams.AttachedOwner:Abs_GetTransform()
  local LookAtRot = self:InternalSweepAdjustCamera(Camera)
  if not self.AttachParams.Rider then
    local HandWorldPoint = OwnerTransform:TransformVector(self.AttachParams.ReadOnlyHandLocalOffset)
    self.Player.viewObj.HandIkTargetActorOffset = HandWorldPoint
  else
    local Movement = self.AttachParams.Rider:GetMovementComponent()
    Movement.Velocity.X = 0
    Movement.Velocity.Y = 0
  end
  self.Player.ueController:SetControlRotation(LookAtRot)
end

function SelfieCameraControl:Interrupt(...)
  Log.Error("[TakePhoto] Interrupt", ...)
  NRCModuleManager:DoCmd(TakePhotosModuleCmd.ExitTakePhotos)
end

function SelfieCameraControl:GatherAttachedOwner()
  local AttachedOwner = self.Player.viewObj
  local Rider
  if self.Player.statusComponent:HasStatus(ProtoEnum.WorldPlayerStatusType.WPST_RIDEALL) and AttachedOwner and AttachedOwner.BP_RideComponent then
    local ridePet = AttachedOwner.BP_RideComponent.RidePet
    if ridePet then
      local bEnableSelfieThisRider = false
      local Mesh = ridePet.Mesh
      local Rotation = Mesh and Mesh:K2_GetComponentRotation()
      local RiderComponent = self.Player:GetRideComponent()
      local RiderBp = self.Player:GetRidePetBP()
      if Rotation and RiderComponent and (RiderComponent.RideMoveType == ProtoEnum.SceneRideAllType.SRAT_GROUND or RiderComponent.RideMoveType == ProtoEnum.SceneRideAllType.SRAT_FLY or RiderComponent.RideMoveType == ProtoEnum.SceneRideAllType.SRAT_SWIM or RiderBp and 0 == RiderComponent.RideMoveType and RiderBp.CharacterMovement.MovementMode == UE.EMovementMode.MOVE_Falling) then
        local ScenePet = self.Player:GetRidePetLua()
        if ScenePet then
          local RideConf = _G.DataConfigManager:GetAllRidePet(ScenePet.config.id, true)
          if RideConf then
            local SelfScenePet = self.Player.viewObj.BP_RideComponent and self.Player.viewObj.BP_RideComponent.ScenePet
            if SelfScenePet == ScenePet then
              if (RideConf.selfie_takephoto_params or "") ~= "" or _G.TakePhotoEditorTools then
                bEnableSelfieThisRider = true
                Rider = ridePet
              end
            else
              bEnableSelfieThisRider = false
              Rider = ridePet
            end
          end
        end
      end
      if bEnableSelfieThisRider then
        AttachedOwner = ridePet
      else
        AttachedOwner = nil
      end
    end
  end
  return AttachedOwner, Rider
end

function SelfieCameraControl:Precheck()
  if self.AttachedOwner then
    return false
  end
  self.Player = _G.NRCModuleManager:DoCmd(_G.PlayerModuleCmd.GET_LOCAL_PLAYER)
  if not self.Player then
    Log.Error("SelfieCameraControl:Precheck false - no local player")
    return false
  end
  self.World = UE4Helper.GetCurrentWorld()
  self.PlayerCameraManager = self.Player:GetUEController().PlayerCameraManager
  local canApply, overrideValues, opCode = self.Player.statusComponent:PreApplyStatus(Enum.WorldPlayerStatusType.WPST_TAKE_PHOTO_SELF)
  if not canApply then
    return false
  end
  if self.Player.statusComponent:HasStatus(ProtoEnum.WorldPlayerStatusType.WPST_RIDEALL_ABILITY) then
    return false
  end
  local AttachParams = self:GatherAttachParams()
  if not AttachParams then
    return false
  end
  if not AttachParams.b2PRider and self:DoCollisionTest(AttachParams.ReadOnlyWorldTransform.Translation) then
    return false
  end
  self.AttachParams = AttachParams
  return true
end

function SelfieCameraControl:GatherAttachRightHand()
  return not self.Player.viewObj.LeftHandCamera
end

function SelfieCameraControl:Apply2PRiderConfig(AttachParams)
  assert(AttachParams)
  AttachParams.bCamera2pRiderRotationDirty = true
  AttachParams.Camera2pRiderRotation = nil
  local ScenePet = self.Player:GetRidePetLua()
  if ScenePet then
    local RideConf = _G.DataConfigManager:GetAllRidePet(ScenePet.config.id, true)
    if RideConf then
      local SelfScenePet = self.Player.viewObj.BP_RideComponent and self.Player.viewObj.BP_RideComponent.ScenePet
      local localPlayer = self.Player
      local playerCameraManager = localPlayer:GetUEController().playerCameraManager
      local AnimationInstance = playerCameraManager:GetCameraAnimInstance()
      if SelfScenePet ~= ScenePet then
        local DefaultPitch = -18
        local DefaultYaw = 180
        local DefaultOffset = 45
        local Camera2pRiderRotation
        if _G.TakePhotoEditorTools then
          local Tls = _G.TakePhotoEditorTools.Get()
          AnimationInstance.IsSelfieCamera2p = true
          AnimationInstance.SelfCamera2pDistance = Tls:GetSelfieData("selfie2p_view_offset_x")
          local Pitch = Tls:GetSelfieData("selfie2p_view_pitch")
          local Yaw = Tls:GetSelfieData("selfie2p_view_yaw")
          if Pitch and Yaw and (0 ~= Pitch or 0 ~= Yaw) then
            Camera2pRiderRotation = UE.FRotator(Pitch, Yaw, 0)
          end
        elseif (RideConf.selfie2p_takephoto_params or "") ~= "" then
          local selfie2p_takephoto_params = RideConf.selfie2p_takephoto_params or ""
          local nums = string.split(selfie2p_takephoto_params, ";")
          for i, num in ipairs(nums) do
            nums[i] = tonumber(num) or 0
          end
          AnimationInstance.IsSelfieCamera2p = true
          AnimationInstance.SelfCamera2pDistance = nums[1] or 0
          local Pitch = nums[2] or 0
          local Yaw = nums[3] or 0
          if Pitch and Yaw and (0 ~= Pitch or 0 ~= Yaw) then
            Camera2pRiderRotation = UE.FRotator(Pitch, Yaw, 0)
          end
        else
          AnimationInstance.IsSelfieCamera2p = true
          AnimationInstance.SelfCamera2pDistance = DefaultOffset
          Camera2pRiderRotation = UE.FRotator(DefaultPitch, DefaultYaw, 0)
        end
        Log.Debug("[TakePhoto] 2p rider, SelfCamera2pDistance=", AnimationInstance.SelfCamera2pDistance, Camera2pRiderRotation)
        AttachParams.Camera2pRiderRotation = Camera2pRiderRotation and Camera2pRiderRotation:ToQuat()
        return AttachParams
      end
    end
  end
  self:Cancel2PRiderConfig()
end

function SelfieCameraControl:Cancel2PRiderConfig()
  local localPlayer = self.Player
  local controller = localPlayer:GetUEController()
  if localPlayer and controller and UE.UObject.IsValid(controller) then
    local playerCameraManager = localPlayer:GetUEController().playerCameraManager
    local AnimationInstance = playerCameraManager:GetCameraAnimInstance()
    AnimationInstance.IsSelfieCamera2p = false
    AnimationInstance.SelfCamera2pDistance = 0
    Log.Debug("[TakePhoto] 2p rider cancel, SelfCamera2pDistance=", AnimationInstance.SelfCamera2pDistance)
  end
end

function SelfieCameraControl:GatherAttachParams()
  local AttachedOwner, Rider = self:GatherAttachedOwner()
  if not AttachedOwner then
    if Rider then
      local AttachParams = {b2PRider = true, Rider = Rider}
      self:Apply2PRiderConfig(AttachParams)
      return AttachParams
    end
    return
  end
  self:Cancel2PRiderConfig()
  local AttachParamsConfigs = self:GatherAttachParamsConfig(Rider)
  local AttachParams = {}
  AttachParams.AttachedOwner = AttachedOwner
  AttachParams.bReadOnlyUsingRightHand = self:GatherAttachRightHand()
  AttachParams.Config = AttachParamsConfigs
  AttachParams.Rider = Rider
  local HorizontalViewOffset = AttachParamsConfigs.HorizontalViewOffset
  local ViewHeightOffset = AttachParamsConfigs.ViewHeightOffset
  local DistanceViewOffset = AttachParamsConfigs.DistanceViewOffset
  local HorizontalCamOffset = AttachParamsConfigs.HorizontalCamOffset
  local InitHeightOffset = AttachParamsConfigs.InitHeightOffset
  local DirFactor = AttachParams.bReadOnlyUsingRightHand and -1 or 1
  local ViewOffset = UE.FVector(0, HorizontalViewOffset * DirFactor, ViewHeightOffset)
  local LocationOffset = UE.FVector(DistanceViewOffset, HorizontalCamOffset * DirFactor, InitHeightOffset)
  local Forward = ViewOffset - LocationOffset
  Forward:Normalize()
  AttachParams.ReadOnlyViewPointOffset = ViewOffset
  AttachParams.ReadOnlyRelativeTransform = UE.FTransform(Forward:ToQuat(), LocationOffset, FVectorOne)
  local HandOffsetX = AttachParamsConfigs.HandOffsetX
  local HandOffsetY = AttachParamsConfigs.HandOffsetY
  local HandOffsetZ = AttachParamsConfigs.HandOffsetZ
  AttachParams.ReadOnlyHandLocalOffset = UE.FVector(HandOffsetX, -DirFactor * HandOffsetY, HandOffsetZ)
  local WorldTransform = UE.UKismetMathLibrary.ComposeTransforms(AttachParams.ReadOnlyRelativeTransform, AttachedOwner:Abs_GetTransform())
  AttachParams.ReadOnlyWorldTransform = WorldTransform
  return AttachParams
end

function SelfieCameraControl:DoCollisionTest(TestPosition)
  local IgnoreActors = {}
  self.Mode:AttachIgnoreActors(IgnoreActors)
  local HitResults, bHit = UE.UKismetSystemLibrary.Abs_SphereTraceMultiForObjects(self.World, TestPosition + self.DeltaToleranceVec, TestPosition - self.DeltaToleranceVec, 20, self.TraceObjectTypes, false, IgnoreActors, UE4.EDrawDebugTrace.None, nil, true, UE4.FLinearColor.Red, UE4.FLinearColor.Green, 10)
  local CollisionActor
  for _, Result in tpairs(HitResults) do
    local Component = Result.Component
    if not Component then
    else
      local Channel = UE.UNRCStatics.ConvertToCollisionChannel(UE.EObjectTypeQuery.Character)
      local Response = Component:GetCollisionResponseToChannel(Channel)
      if Response == UE.ECollisionResponse.ECR_Block then
        CollisionActor = Result.Actor
        if CollisionActor then
          break
        end
      end
      Channel = UE.ECollisionChannel.ECC_Camera
      Response = Component:GetCollisionResponseToChannel(Channel)
      if Response == UE.ECollisionResponse.ECR_Block then
        CollisionActor = Result.Actor
        if CollisionActor then
          break
        end
      end
    end
  end
  return CollisionActor
end

function SelfieCameraControl:Enter()
  self.bPendingExit = false
  self.bHandActionDirty = false
  self.Overlaps = {}
  self:InternalClearInput()
  self.SelfieCameraResource.OnSpawned:Clear()
  if not self.AttachParams.b2PRider then
    self.SelfieCameraResource.OnSpawned:Add(self, self.OnCameraReady)
    self.SelfieCameraResource:ConditionalSpawn(self.AttachParams.ReadOnlyWorldTransform)
    self:InternalAttachComponent()
  end
end

function SelfieCameraControl:Exit()
  self.bPendingExit = false
  self:Cancel2PRiderConfig()
  self:ResetOverlaps()
  local Camera = self.SelfieCameraResource:GetCamera()
  if Camera and UE.UObject.IsValid(Camera) then
    TakePhotosUtils.ExistCameraFromSelfieToWorld()
  end
  self:InternalDetachComponent()
  self.SelfieCameraResource:DestroyCamera()
  self.bHandActionDirty = false
end

function SelfieCameraControl:ConsumeHandActionChangeRequest()
  local bHandActionDirty = self.bHandActionDirty
  self.bHandActionDirty = false
  return bHandActionDirty
end

function SelfieCameraControl:InternalDetachComponent()
  if self.Player.viewObj and UE.UObject.IsValid(self.Player.viewObj) then
    self.Player.viewObj.HandIkTargetActor = nil
    if self.AttachParams and not self.AttachParams.b2PRider then
      local RidePet = self.Player:GetRidePetBP()
      if RidePet then
        RidePet.CharacterMovement:EnableMovementMode(UE.ERocoCustomMovementMode.MOVE_Climbing)
        RidePet.CharacterMovement:EnableMovementMode(UE.ERocoCustomMovementMode.MOVE_ClimbWater)
      end
    end
  end
  local Camera = self.SelfieCameraResource:GetCamera()
  if Camera and UE.UObject.IsValid(Camera) then
    Camera:K2_GetRootComponent():SetAbsolute(false, false, false)
  end
  self.AttachParams = nil
  self.bCameraEntered = false
  NRCModuleManager:DoCmd(TakePhotosModuleCmd.SetSelfiePlayerLookAtOffset, true)
  self.Player:GetHeadLookAtComponent():ResetHeadLookAtViewport()
end

function SelfieCameraControl:OnCameraReady()
  self:InternalAttachComponent()
end

function SelfieCameraControl:GetCamera()
  return self.SelfieCameraResource:GetCamera()
end

function SelfieCameraControl:InternalAttachComponent()
  if self.bCameraEntered then
    return
  end
  if not self.AttachParams then
    return
  end
  if self.AttachParams.b2PRider then
    return
  end
  local Camera = self.SelfieCameraResource:Process()
  if not Camera or not UE4.UObject.IsValid(Camera) then
    return
  end
  if not self.AttachParams.AttachedOwner then
    self:Interrupt("cannot found attached owner")
    return
  end
  Camera:K2_AttachToActor(self.AttachParams.AttachedOwner, "", UE.EAttachmentRule.KeepWorld, UE.EAttachmentRule.KeepWorld, UE.EAttachmentRule.KeepWorld, false)
  Camera:K2_SetActorRelativeTransform(self.AttachParams.ReadOnlyRelativeTransform, false, nil, true)
  local CameraComponent = Camera:GetComponentByClass(UE.UCameraComponent)
  CameraComponent:SetFieldOfView(self.Mode:GetFov())
  TakePhotosUtils.ToggleCameraFromWorldToSelfie(Camera)
  self.bCameraEntered = true
  self.DesiredHeight = self.AttachParams.ReadOnlyRelativeTransform.Translation.Z
  if self.AttachParams.Rider then
    self.Player.viewObj.HandIkTargetActor = nil
  else
    self.Player.viewObj.HandIkTargetActor = Camera
  end
  NRCModuleManager:DoCmd(TakePhotosModuleCmd.SetSelfiePlayerLookAtOffset)
  self.Player:GetHeadLookAtComponent():SetHeadLookAtViewport(-0.1, 30, 0, 0)
  local RidePet = self.Player:GetRidePetBP()
  if RidePet then
    RidePet.CharacterMovement:DisableMovementMode(UE.ERocoCustomMovementMode.MOVE_Climbing)
    RidePet.CharacterMovement:DisableMovementMode(UE.ERocoCustomMovementMode.MOVE_ClimbWater)
  end
  return true
end

function SelfieCameraControl:InternalAdjustHand(DesiredHeight)
  local Params = self:GatherAttachParams()
  if not Params then
    self:Interrupt("invalid")
    return
  end
  local Camera = self.SelfieCameraResource:GetCamera()
  if Camera then
    self.AttachParams = Params
    local RelativeTransform = Camera:K2_GetRootComponent():GetRelativeTransform()
    RelativeTransform.Translation.Y = self.AttachParams.ReadOnlyRelativeTransform.Translation.Y
    Camera:K2_SetActorRelativeTransform(RelativeTransform, false, nil, true)
    self.DesiredHeight = DesiredHeight
  end
end

function SelfieCameraControl:Sync2pRiderAnimationInstanceFov()
  local FovValue = self.Mode:GetFov()
  local localPlayer = self.Player
  local playerCameraManager = localPlayer:GetUEController().playerCameraManager
  local AnimationInstance = playerCameraManager:GetCameraAnimInstance()
  AnimationInstance.SelfCamera2pFov = FovValue
end

function SelfieCameraControl:Tick2pRider(Dt)
  if not self.AttachParams.Camera2pRiderRotation then
    return
  end
  if not self.AttachParams.Rider or not UE.UObject.IsValid(self.AttachParams.Rider) then
    return
  end
  local MeshComponent = self.AttachParams.Rider:K2_GetRootComponent()
  if not MeshComponent then
    return
  end
  self:Sync2pRiderAnimationInstanceFov()
  if not self.Player.ueController.BP_RocoCameraControlComponent._isControllingView then
    if self.AttachParams.bCamera2pRiderRotationDirty then
      self.AttachParams.bCamera2pRiderRotationDirty = false
      local WorldRotation = MeshComponent:Abs_K2_GetComponentToWorld():TransformRotation(self.AttachParams.Camera2pRiderRotation)
      local WorldRotator = WorldRotation:ToRotator()
      self.Player.ueController:SetControlRotation(WorldRotator)
    end
  else
    local WorldRotator = self.Player.ueController:GetControlRotation()
    local LocalRotation = MeshComponent:Abs_K2_GetComponentToWorld():InverseTransformRotation(WorldRotator:ToQuat())
    self.AttachParams.Camera2pRiderRotation = LocalRotation
  end
end

return SelfieCameraControl

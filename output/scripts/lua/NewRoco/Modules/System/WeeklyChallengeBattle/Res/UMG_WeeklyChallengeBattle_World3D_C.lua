local UIUtils = require("NewRoco.Utils.UIUtils")
local NRCResourceManagerEnum = require("Core.Service.ResourceManager.NRCResourceManagerEnum")
local LuaMathUtils = require("NewRoco.Utils.LuaMathUtils")
local UMG_WeeklyChallengeBattle_World3D_C = _G.NRCPanelBase:Extend("UMG_WeeklyChallengeBattle_World3D_C")

function UMG_WeeklyChallengeBattle_World3D_C:OnActive()
end

function UMG_WeeklyChallengeBattle_World3D_C:OnDeactive()
end

function UMG_WeeklyChallengeBattle_World3D_C:OnAddEventListener()
end

function UMG_WeeklyChallengeBattle_World3D_C:OnConstruct()
  self._refActorIsolateWorld = nil
  self._playerController = UE4.UGameplayStatics.GetPlayerController(self, 0)
  self.MainCameraActor = nil
  self.skillCamera = nil
  self.skillCameraMesh = nil
  self.defaltLocation = UE4.FRotator(0, 0, 0)
  self.targetLocation = UE4.FRotator(0, 0, 0)
  self.targetRotate = 0
  self.duration = 1.0
  self.elapsedTime = 0.0
  self.isMoving = false
  self._waitingAnimReady = false
  self._animReadyFrameCount = 0
  self.npcHeightOffsetMap = {}
  self.npcHeightOffsetMap[12010] = 10
  self._currentModelId = nil
  if not self.previewWorld and self.PreviewWorld then
    self.previewWorld = self.PreviewWorld
  end
end

function UMG_WeeklyChallengeBattle_World3D_C:InitSceneCapture()
  local worldView = self.previewWorld or self.PreviewWorld
  if not worldView or not UE.UObject.IsValid(worldView) then
    Log.Error("UMG_WeeklyChallengeBattle_World3D_C:InitSceneCapture previewWorld invalid")
    self.MainCameraActor = nil
    self.captureComponent = nil
    return
  end
  self.MainCameraActor = worldView:getActorByName("DefaultSceneCapture") or worldView:getActorByName("MainCamera") or worldView:getActorByName("MainCameraActor")
  if not self.MainCameraActor or not UE.UObject.IsValid(self.MainCameraActor) then
    Log.Error("UMG_WeeklyChallengeBattle_World3D_C:InitSceneCapture camera actor not found")
    self.captureComponent = nil
    return
  end
  self.captureComponent = self.MainCameraActor:GetComponentByClass(UE4.USceneCaptureComponent2D)
  if not self.captureComponent or not UE.UObject.IsValid(self.captureComponent) then
    Log.Error("UMG_WeeklyChallengeBattle_World3D_C:InitSceneCapture capture component missing")
    return
  end
  if self.captureComponent.showOnlyActors then
    self.captureComponent.showOnlyActors:Clear()
  end
  if self.captureComponent.TextureTarget then
    UE4.UNRCStatics.ChangeTextureToMatchScreen(self.captureComponent.TextureTarget, UE4Helper.GetCurrentWorld(), 0)
  end
  if not self.bDefaultCenter then
    local rotation = UE4.FRotator()
    rotation.Pitch = -5.0
    rotation.Yaw = -172
    rotation.Roll = 0.0
    local trans = UE4.FTransform(rotation:ToQuat(), UE4.FVector(200, -16, 55), UE4.FVector(-1, -1, -1))
    if UE.UObject.IsValid(self.MainCameraActor) then
      self.MainCameraActor:Abs_K2_SetActorTransform_WithoutHit(trans)
    end
  else
    local rotation = UE4.FRotator()
    rotation.Pitch = -5.0
    rotation.Yaw = -172
    rotation.Roll = 0.0
    local trans = UE4.FTransform(rotation:ToQuat(), UE4.FVector(200, 25, 55), UE4.FVector(-1, -1, -1))
    if UE.UObject.IsValid(self.MainCameraActor) then
      self.MainCameraActor:Abs_K2_SetActorTransform_WithoutHit(trans)
    end
  end
end

function UMG_WeeklyChallengeBattle_World3D_C:ResetRotate()
  self._resetRotate = true
end

function UMG_WeeklyChallengeBattle_World3D_C:MoveToLocation(targetLocation, targetRotate, duration)
  self.targetLocation = targetLocation
  self.targetRotate = targetRotate
  self.duration = duration
  self.elapsedTime = 0.0
  self.isMoving = true
end

function UMG_WeeklyChallengeBattle_World3D_C:Update(deltaTime)
  if self.isMoving then
    self.elapsedTime = self.elapsedTime + deltaTime
    local alpha = self.elapsedTime / self.duration
    if alpha >= 1.0 then
      alpha = 1.0
      self.isMoving = false
    end
    if self.targetLocation then
      local startLocation = self._refActorIsolateWorld:Abs_K2_GetActorLocation()
      local newLocation = LuaMathUtils.LerpVector(startLocation, self.targetLocation, alpha)
      self._refActorIsolateWorld:Abs_K2_SetActorLocation_WithoutHit(UE4.FVector(newLocation.X, newLocation.Y, newLocation.Z))
    end
    if self.targetRotate then
      local startRotate = self._refActorIsolateWorld:K2_GetActorRotation()
      local newRotate = LuaMathUtils.LerpVector(startRotate, UE4.FRotator(startRotate.Pitch, self.targetRotate, startRotate.Roll), alpha)
      self._refActorIsolateWorld:K2_SetActorRotation(newRotate, false)
    end
  end
end

function UMG_WeeklyChallengeBattle_World3D_C:Tick(MyGeometry, InDeltaTime)
  if self._refActorIsolateWorld and not self.bDefaultCenter then
    self:Update(InDeltaTime)
  end
  if self._waitingAnimReady and self._refActorIsolateWorld and UE.UObject.IsValid(self._refActorIsolateWorld) then
    self._animReadyFrameCount = self._animReadyFrameCount + 1
    local mesh = self._refActorIsolateWorld:GetComponentByClass(UE4.USkeletalMeshComponent)
    if mesh then
      local animInstance = mesh:GetAnimInstance()
      if animInstance and self._animReadyFrameCount >= 5 or self._animReadyFrameCount >= 15 then
        self._waitingAnimReady = false
        self._animReadyFrameCount = 0
        self:ShowModelAndFinish()
      end
    elseif self._animReadyFrameCount >= 10 then
      self._waitingAnimReady = false
      self._animReadyFrameCount = 0
      self:ShowModelAndFinish()
    end
  end
end

function UMG_WeeklyChallengeBattle_World3D_C:GetDefaultAvatarResPath(gender)
  local avatarResPath = ""
  if gender == _G.ProtoEnum.ESexValue.SEX_MALE then
    avatarResPath = UEPath.DEFAULT_AVATAR_PLAYER_MALE
  elseif gender == _G.ProtoEnum.ESexValue.SEX_FEMALE then
    avatarResPath = UEPath.DEFAULT_AVATAR_PLAYER_FEMALE
  end
  return avatarResPath
end

function UMG_WeeklyChallengeBattle_World3D_C:SetModule(id, appearanceInfo, bDefaultCenter, onLoadFinishCallback, callbackOwner)
  self._currentModelId = id
  self.Offset = self:_GetNpcHeightOffset()
  self.bDefaultCenter = bDefaultCenter
  self.onLoadFinishCallback = onLoadFinishCallback
  self.callbackOwner = callbackOwner
  self:InitSceneCapture()
  if UE.UObject.IsValid(self._refActorIsolateWorld) then
    self.PreviewWorld:DestroyActor(self._refActorIsolateWorld)
    self._refActorIsolateWorld = nil
  end
  self.Appearance = nil
  if appearanceInfo then
    self.Appearance = appearanceInfo
    local gender = appearanceInfo.sex
    self.path = self:GetDefaultAvatarResPath(gender)
    Log.Error("UMG_Leve_World3D_C:SetModule \231\142\169\229\174\182\230\168\161\229\158\139\232\183\175\229\190\132 ", self.path)
  else
    local moduleId = id
    local moduleConf = _G.DataConfigManager:GetModelConf(moduleId)
    local modelPath = moduleConf.path
    self.path = modelPath
    Log.Error("UMG_Leve_World3D_C:SetModule \230\168\161\229\158\139\232\183\175\229\190\132 ", modelPath)
  end
  self:UnDelay()
  self.DelayId = _G.NRCViewBase:DelayFrames(1, self.DelayedRetry, self)
end

function UMG_WeeklyChallengeBattle_World3D_C:DelayedRetry()
  if self.path then
    self:UnLoad()
    self.Request = _G.NRCResourceManager:LoadResAsync(self, self.path, NRCResourceManagerEnum.Priority.IMMEDIATELY, 0, self.OnLoadModuelFinished, self.ModelLoadFailed, self.UnLoad)
  end
end

function UMG_WeeklyChallengeBattle_World3D_C:OnLoadModuelFinished(resRequest, modelClass)
  if not modelClass then
    Log.Error("UMG_Leve_World3D_C:OnLoadModuelFinished \230\168\161\229\158\139\232\183\175\229\190\132\233\148\153\232\175\175 [%s].", resRequest or "")
    return
  end
  if UE.UObject.IsValid(self.PreviewWorld) then
    local transform
    local location = UE4.FVector(0, 0, 0)
    local deltaRot = UE4.FRotator(0, 0, 0)
    transform = UE4.FTransform(deltaRot:ToQuat(), location)
    self._spawnInitialRot = deltaRot
    self._refActorIsolateWorld = self.PreviewWorld:SpawnActor(modelClass, transform)
    if UE.UObject.IsValid(self._refActorIsolateWorld) then
      self._refActorIsolateWorld:SetActorHiddenInGame(true)
    end
    if UE.UObject.IsValid(self._refActorIsolateWorld) and not self.Appearance then
      self._refActorIsolateWorld:InitOutSceneAsync(self, self.OnPetLoaded)
    else
      local fashionIds = self.Appearance.fashion_wear_id
      local salondatas = self.Appearance.salon_item_data
      self:SetAvatarSuit(self._refActorIsolateWorld, fashionIds, salondatas)
      local avatarMesh = self._refActorIsolateWorld:GetComponentByClass(UE4.USkeletalMeshComponent)
      if avatarMesh then
        avatarMesh.bForceMipStreaming = true
        avatarMesh:SetForcedLOD(1)
        avatarMesh.StreamingDistanceMultiplier = 999
        avatarMesh.bNeverDistanceCull = true
        if avatarMesh.SkeletalMesh then
          UE4.UNRCStatics.ForceUpdateStreamingAssets(avatarMesh.SkeletalMesh, 30)
        end
      end
      self:BeginWaitAnimReady()
    end
  end
end

function UMG_WeeklyChallengeBattle_World3D_C:SetAvatarSuit(avatarActor, fashionIds, salonIds, gender)
  local defaultSuitClass
  if nil == gender then
    local localPlayer = _G.NRCModuleManager:DoCmd(_G.PlayerModuleCmd.GET_LOCAL_PLAYER)
    if nil == localPlayer then
      Log.Error("player is nil")
      return
    end
    gender = localPlayer.gender
  end
  local AnimComponent = avatarActor:GetComponentByClass(UE4.URocoAnimComponent)
  local mesh = avatarActor:GetComponentByClass(UE4.USkeletalMeshComponent)
  if 1 == gender then
    defaultSuitClass = _G.NRCBigWorldPreloader:Get(UEPath.DEFAULT_AVATAR_SUIT_MALE)
    self:LoadResAsyncAnimClass(mesh, UEPath.ABP_CARD_PLAYER_MALE)
    self:LoadResAsyncAnimConfig(AnimComponent, UEPath.ANIM_CONFIG_MALE)
  elseif 2 == gender then
    defaultSuitClass = _G.NRCBigWorldPreloader:Get(UEPath.DEFAULT_AVATAR_SUIT_FEMALE)
    self:LoadResAsyncAnimClass(mesh, UEPath.ABP_CARD_PLAYER_FEMALE)
    self:LoadResAsyncAnimConfig(AnimComponent, UEPath.ANIM_CONFIG_FEMALE)
  end
  local defaultSuitObj = NewObject(defaultSuitClass, _G.UE4Helper.GetCurrentWorld())
  defaultSuitObj.Gender = gender
  if salonIds and #salonIds > 0 then
    local salonWearIds = {}
    for k, v in ipairs(salonIds) do
      if v.item_wear_id and 0 ~= v.item_wear_id then
        local SalonItemConf = _G.DataConfigManager:GetSalonItemConf(v.item_wear_id)
        if SalonItemConf then
          local avatarId = SalonItemConf.avatar_id
          local colorId = SalonItemConf.texture_id
          local fullSalonId = self:GetFullSalonId(avatarId, colorId)
          table.insert(salonWearIds, fullSalonId)
        end
      end
    end
    defaultSuitObj:SetSalons(salonWearIds)
  end
  if fashionIds and #fashionIds > 0 then
    for k, v in ipairs(fashionIds) do
      if 0 ~= v then
        local fashionItemConf = _G.DataConfigManager:GetFashionItemConf(v)
        if fashionItemConf then
          local bBodyType, avatarEnum = UIUtils.GetAvatarEnumByConfigEnumFashion(fashionItemConf.type)
          if bBodyType then
            defaultSuitObj:SetBody(v, 0)
          else
            defaultSuitObj:SetBody(v, 0)
          end
        else
          Log.Error("fashion\228\184\141\229\173\152\229\156\168")
        end
      end
    end
  end
  if avatarActor then
    local mesh = avatarActor:GetComponentByClass(UE4.USkeletalMeshComponent)
    self.avatarSystem = UE.USubsystemBlueprintLibrary.GetGameInstanceSubsystem(UE4Helper.GetCurrentWorld(), UE.UAvatarSubsystem)
    if self.avatarSystem.OnSwitchAvatarSuitComplete then
      self.avatarSystem.OnSwitchAvatarSuitComplete:Add(self.avatarSystem, self.RecoverAllStatus)
    end
    self.ID = self.avatarSystem:StartSwitchAvatarSuit(mesh, defaultSuitObj)
    self:SetAnimInstance()
    self:PlayAnimByName("YesLoop")
  else
    Log.Error("\228\186\186\231\137\169\231\148\159\230\136\144\229\164\177\232\180\165")
  end
end

function UMG_WeeklyChallengeBattle_World3D_C:LoadResAsyncAnimClass(mesh, Path)
  local asset = self.module:GetRes(Path, "Leve_BattleArray")
  mesh:SetAnimClass(asset)
end

function UMG_WeeklyChallengeBattle_World3D_C:LoadResAsyncAnimConfig(AnimComponent, Path)
  local asset = self.module:GetRes(Path, "Leve_BattleArray")
  AnimComponent:SetAnimConfig(asset)
end

function UMG_WeeklyChallengeBattle_World3D_C:SetAnimInstance()
  if self._refActorIsolateWorld then
    local AnimComponent = self._refActorIsolateWorld:GetComponentByClass(UE4.URocoAnimComponent)
    if AnimComponent then
      AnimComponent:InitAnimInstance()
    end
  end
end

function UMG_WeeklyChallengeBattle_World3D_C:RecoverAllStatus(ID, Entrance)
end

function UMG_WeeklyChallengeBattle_World3D_C:PlayAnimByNameInfo(AnimName)
  if self._refActorIsolateWorld then
    local RocoAnimComponent = self._refActorIsolateWorld:GetComponentByClass(UE4.URocoAnimComponent)
    if RocoAnimComponent then
      local CurrentMontage = RocoAnimComponent:PrepareMontageByName(AnimName, "DefaultSlot", 0.0, 0.0, -1)
      RocoAnimComponent:PlayAnim(CurrentMontage, 1, 0, 0, 0, -1, 0)
    end
  end
end

function UMG_WeeklyChallengeBattle_World3D_C:PlayAnimByName(AnimName)
  if self._refActorIsolateWorld then
    local RocoAnimComponent = self._refActorIsolateWorld:GetComponentByClass(UE4.URocoAnimComponent)
    if RocoAnimComponent then
      RocoAnimComponent:PlayAnimByName(AnimName, 1, 0, 0, 0, -1, 0)
    end
  end
end

function UMG_WeeklyChallengeBattle_World3D_C:GetFullSalonId(configId, colorIndex)
  if colorIndex > 0 then
    colorIndex = colorIndex - 1
  end
  local fullSalonId = configId * 100 + colorIndex
  return fullSalonId
end

function UMG_WeeklyChallengeBattle_World3D_C:ModelLoadFailed(resRequest)
  Log.Error("UMG_Leve_World3D_C:ModelLoadFailed \230\168\161\229\158\139\229\138\160\232\189\189\229\164\177\232\180\165 [%s].", resRequest or "")
  _G.NRCResourceManager:UnLoadRes(resRequest)
end

function UMG_WeeklyChallengeBattle_World3D_C:UnLoad()
  if self.Request then
    _G.NRCResourceManager:UnLoadRes(self.Request)
    self.Request = nil
  end
end

function UMG_WeeklyChallengeBattle_World3D_C:UnDelay()
  if self.DelayId then
    _G.DelayManager:CancelDelayById(self.DelayId)
    self.DelayId = nil
  end
  self._waitingAnimReady = false
  self._animReadyFrameCount = 0
end

function UMG_WeeklyChallengeBattle_World3D_C:OnPetLoaded(actor)
  local location = UE4.FVector(0, 0, 0)
  actor:PlayAnimByName("idle", 1, 0, 0, 0, -1)
  local scale = 1
  actor.CharacterMovement:SetMovementMode(UE4.EMovementMode.MOVE_Custom, 0)
  local mesh = actor:GetComponentByClass(UE4.USkeletalMeshComponent)
  mesh.bForceMipStreaming = true
  mesh:SetForcedLOD(1)
  mesh.StreamingDistanceMultiplier = 999
  mesh.bNeverDistanceCull = true
  if mesh.SkeletalMesh then
    UE4.UNRCStatics.ForceUpdateStreamingAssets(mesh.SkeletalMesh, 30)
  end
  self.SkeletalMesh = mesh
  actor:SetActorScale3D(UE4.FVector(scale, scale, scale))
  location = UE4.FVector(location.X, location.Y, location.Z + self.Offset)
  actor:Abs_K2_SetActorLocation_WithoutHit(location)
  self._refActorIsolateWorld = actor
  self:BeginWaitAnimReady()
end

function UMG_WeeklyChallengeBattle_World3D_C:_GetNpcHeightOffset()
  if self._currentModelId and self.npcHeightOffsetMap[self._currentModelId] then
    return self.npcHeightOffsetMap[self._currentModelId]
  end
  return 0
end

function UMG_WeeklyChallengeBattle_World3D_C:BeginWaitAnimReady()
  self._waitingAnimReady = true
  self._animReadyFrameCount = 0
end

function UMG_WeeklyChallengeBattle_World3D_C:ShowModelAndFinish()
  if UE.UObject.IsValid(self._refActorIsolateWorld) then
    self._refActorIsolateWorld:SetActorHiddenInGame(false)
  end
  if self.captureComponent and self.captureComponent.showOnlyActors and self._refActorIsolateWorld then
    self.captureComponent.showOnlyActors:Add(self._refActorIsolateWorld)
  end
  if UE.UObject.IsValid(self._refActorIsolateWorld) and self._spawnInitialRot and not self.bDefaultCenter then
    self._refActorIsolateWorld:K2_SetActorRotation(self._spawnInitialRot, false)
  end
  if self.onLoadFinishCallback then
    if self.callbackOwner then
      self.onLoadFinishCallback(self.callbackOwner)
    else
      self.onLoadFinishCallback()
    end
  end
end

function UMG_WeeklyChallengeBattle_World3D_C:LoadFinish()
  self:ShowModelAndFinish()
end

function UMG_WeeklyChallengeBattle_World3D_C:MoveCenter()
  if UE.UObject.IsValid(self._refActorIsolateWorld) and not self.Appearance then
    local location = UE4.FVector(25, -41, 0)
    self:MoveToLocation(location, 8, 2)
  else
    local location = UE4.FVector(41, 25, 0)
    self:MoveToLocation(location, 8, 2)
  end
end

function UMG_WeeklyChallengeBattle_World3D_C:MoveResest()
  local location = UE4.FVector(0, 0, 0)
  self:MoveToLocation(location, 0, 2)
end

function UMG_WeeklyChallengeBattle_World3D_C:SetSkillCamera(Event, Skill)
  self.skillCamera = Skill:GetBlackboard():GetValueAsObject("camActor_0001")
  self.skillCameraMesh = Skill:GetBlackboard():GetValueAsObject("camActor_0001_SA")
end

function UMG_WeeklyChallengeBattle_World3D_C:RemoveSkillCamera()
  if self.skillCamera then
    self.skillCamera = nil
  end
  if self.skillCameraMesh then
    self.skillCameraMesh = nil
  end
end

function UMG_WeeklyChallengeBattle_World3D_C:OnDestruct()
  self:UnLoad()
  self:UnDelay()
  if UE.UObject.IsValid(self._refActorIsolateWorld) then
    self.PreviewWorld:DestroyActor(self._refActorIsolateWorld)
    self._refActorIsolateWorld = nil
  end
  if self.captureComponent and self.captureComponent.showOnlyActors then
    self.captureComponent.showOnlyActors:Clear()
  end
end

return UMG_WeeklyChallengeBattle_World3D_C

local BP_RideFxComponent_C = NRCClass()
local PetIDOffset = 100000
local ModeIDOffset = 1000
local FxPathMap = {
  [Enum.SceneRideAllType.SRAT_GROUND] = "/Game/ArtRes/Effects/Particle/Scene/Pet/Ride/Landward/",
  [Enum.SceneRideAllType.SRAT_SWIM] = "/Game/ArtRes/Effects/Particle/Scene/Pet/Ride/Swim/",
  [Enum.SceneRideAllType.SRAT_FLY] = "/Game/ArtRes/Effects/Particle/Scene/Pet/Ride/Fly/",
  [Enum.SceneRideAllType.SRAT_CLIMB_WATER] = "/Game/ArtRes/Effects/Particle/Scene/Pet/Ride/Waterfall/",
  [Enum.SceneRideAllType.SRAT_KEEP_BALANCE] = "/Game/ArtRes/Effects/Particle/Scene/Pet/Ride/DuLunChe/",
  [99] = "/Game/ArtRes/Effects/Particle/Scene/Pet/Ride/Buff/"
}
local CacheTime = 5

function BP_RideFxComponent_C:Ctor()
  self.RideEffectsConfig = _G.DataConfigManager:GetAllByTableID(_G.DataConfigManager.ConfigTableId.RIDE_EFFECTS)
  self.FxCache = {}
  self.ResidualFxList = {}
end

function BP_RideFxComponent_C:ReceiveBeginPlay()
  self.Overridden.ReceiveBeginPlay(self)
  UpdateManager:Register(self)
end

function BP_RideFxComponent_C:ReceiveEndPlay(EndPlayReason)
  self.Overridden.ReceiveEndPlay(self, EndPlayReason)
  UpdateManager:UnRegister(self)
  for i, _Cache in ipairs(self.FxCache) do
    local FxActor = _Cache.Fx
    if UE.UObject.IsValid(FxActor) then
      FxActor:K2_DestroyActor()
    end
  end
  for i, _Cache in ipairs(self.ResidualFxList) do
    local FxActor = _Cache.Fx
    if UE.UObject.IsValid(FxActor) then
      FxActor:K2_DestroyActor()
    end
  end
end

function BP_RideFxComponent_C:GetFxInfo(StatusName)
  local RideComp = self.RideComponent
  if not RideComp then
    local RidePet = self.CharacterOwner
    if not RidePet then
      return
    end
    local Pawn = RidePet:GetOwner()
    RideComp = Pawn and Pawn.BP_RideComponent
    if not RideComp then
      return
    end
    self.RideComponent = RideComp
  end
  local RowInfo = self:GetRowByName(StatusName)
  return RowInfo
end

function BP_RideFxComponent_C:GetFxActorByCache(FxName)
  if not next(self.FxCache) then
    return false
  end
  local List = self.FxCache
  local Index = #List
  local bFind = false
  for i = Index, 1, -1 do
    local FxActor = List[i] and List[i].Fx
    if UE.UObject.IsValid(FxActor) then
      local Asset = FxActor.Fx:GetAsset()
      if Asset and Asset:GetName() == FxName then
        bFind = true
        Index = i
        break
      end
    else
      table.remove(List, i)
    end
  end
  local Cache = List[Index]
  local FxActor
  if Cache then
    if UE.UObject.IsValid(Cache.Fx) then
      FxActor = Cache.Fx
      FxActor:K2_SetActorRelativeTransform(UE4.FTransform(), false, UE4.FHitResult(), true)
    else
      bFind = false
    end
    table.remove(List, Index)
  end
  return bFind, FxActor
end

function BP_RideFxComponent_C:SetNewOwner(FxActor, NewOwner)
  UE4.UNRCStatics.SetActorOwner(FxActor, NewOwner)
  if NewOwner then
    if NewOwner.GetActorHidden then
      FxActor:SetActorHiddenInGame(NewOwner:GetActorHidden())
    else
      FxActor:SetActorHiddenInGame(NewOwner.bHidden)
    end
  else
    FxActor:SetActorHiddenInGame(true)
  end
end

function BP_RideFxComponent_C:SpawnFxActor(FxName, FxAssetPath, SocketName, Offset, Scale)
  local bSameFx, FxActor = self:GetFxActorByCache(FxName)
  if not FxActor then
    FxActor = UE4Helper.GetCurrentWorld():SpawnActor(self.FxActorClass, UE4.FTransform(), UE4.ESpawnActorCollisionHandlingMethod.AlwaysSpawn)
    if not FxActor then
      return
    end
  end
  self:SetNewOwner(FxActor, self.RideComponent.RidePet)
  FxActor:K2_AttachToComponent(self.RideComponent.RidePet.Mesh, SocketName, UE4.EAttachmentRule.SnapToTarget, UE4.EAttachmentRule.SnapToTarget, UE4.EAttachmentRule.SnapToTarget, false)
  local Fx = FxActor.Fx
  Fx:K2_SetRelativeLocation(Offset, false, UE4.FHitResult(), true)
  Fx:SetRelativeScale3D(Scale)
  if bSameFx then
    local Asset = Fx:GetAsset()
    Fx:SetAsset(nil)
    Fx:SetAsset(Asset)
    FxActor:SetFxHidden(false, false)
  else
    Fx:SetAsset()
    _G.NRCResourceManager:LoadResAsync(self, FxAssetPath, -1, 10, function(_, req, FxAsset)
      if UE.UObject.IsValid(FxActor) then
        FxActor.Fx:SetAsset(FxAsset)
        FxActor:SetFxHidden(false, false)
      end
    end)
  end
  return FxActor
end

function BP_RideFxComponent_C:LuaStopMoveFx(FxActor, ResidualTime)
  if not UE.UObject.IsValid(FxActor) then
    return
  end
  for i, _Cache in ipairs(self.ResidualFxList) do
    if _Cache.Fx == FxActor then
      Log.Warning("BP_RideFxComponent_C:LuaStopMoveFx Repeated Add")
      return
    end
  end
  for i, _Cache in ipairs(self.FxCache) do
    if _Cache.Fx == FxActor then
      Log.Warning("BP_RideFxComponent_C:LuaStopMoveFx Repeated Add")
      return
    end
  end
  local Cache = {Fx = FxActor, Time = ResidualTime}
  if ResidualTime and ResidualTime > 0 then
    Cache.bHidden = false
    table.insert(self.ResidualFxList, Cache)
  else
    Cache.Time = CacheTime
    table.insert(self.FxCache, Cache)
    self:SetNewOwner(FxActor)
  end
end

function BP_RideFxComponent_C:LuaPlayMoveFxByStatus(StatusName, FxActors)
  local RowInfo = self:GetFxInfo(StatusName)
  if not RowInfo then
    return FxActors
  end
  local PetID = self.RideComponent.ScenePet.config.id
  local StatusID = RowInfo.StatusID
  local ConfigID = PetIDOffset * PetID + StatusID
  local FxInfo = self.RideEffectsConfig[ConfigID]
  local AssetPath
  if FxInfo then
    local MoveType = math.floor(StatusID / ModeIDOffset)
    local group = FxInfo.ride_pet_fx_id_group
    local FxName
    for i, _info in ipairs(group) do
      FxName = _info.ride_pet_fx_name
      AssetPath = string.format("%s%s.%s", FxPathMap[MoveType], FxName, FxName)
      local Fx = self:SpawnFxActor(FxName, AssetPath, _info.ride_pet_fx_attach_point, UE4.FVector(_info.ride_pet_fx_offset[1], _info.ride_pet_fx_offset[2], _info.ride_pet_fx_offset[3]), UE4.FVector(_info.ride_pet_fx_scale[1], _info.ride_pet_fx_scale[2], _info.ride_pet_fx_scale[3]))
      if Fx then
        FxActors:Add(Fx)
      else
        Log.Warning("BP_RideFxComponent_C:LuaPlayMoveFxByStatus No FxActor", AssetPath)
      end
    end
  else
    local FxName = RowInfo.Effect:GetAssetName()
    AssetPath = string.format("%s.%s", RowInfo.Effect:GetLongPackageName(), FxName)
    local Fx = self:SpawnFxActor(FxName, AssetPath, UE4.URocoMeshAttachPointMethod.AttachPointTypeToName(RowInfo.AttachmentPoint), RowInfo.Offset, self.EffectScale)
    if Fx then
      FxActors:Add(Fx)
    else
      Log.Warning("BP_RideFxComponent_C:LuaPlayMoveFxByStatus No FxActor", AssetPath)
    end
  end
  return FxActors
end

function BP_RideFxComponent_C:OnTick(DeltaSeconds)
  if next(self.FxCache) then
    local List = self.FxCache
    for i = #List, 1, -1 do
      local Cache = List[i]
      if DeltaSeconds < Cache.Time then
        Cache.Time = Cache.Time - DeltaSeconds
      else
        local FxActor = Cache.Fx
        if UE.UObject.IsValid(FxActor) then
          FxActor:K2_DestroyActor()
        end
        table.remove(List, i)
      end
    end
  end
  if next(self.ResidualFxList) then
    local List = self.ResidualFxList
    for i = #List, 1, -1 do
      local Cache = List[i]
      if DeltaSeconds < Cache.Time then
        Cache.Time = Cache.Time - DeltaSeconds
        if Cache.Time <= 0.5 and not Cache.bHidden then
          if UE.UObject.IsValid(Cache.Fx) then
            Cache.bHidden = true
            Cache.Fx:SetFxHidden(true, false)
          else
            table.remove(List, i)
          end
        end
      else
        table.remove(List, i)
        local FxActor = Cache.Fx
        if UE.UObject.IsValid(FxActor) then
          self:SetNewOwner(FxActor)
          Cache.Time = CacheTime
          table.insert(self.FxCache, Cache)
        end
      end
    end
  end
end

return BP_RideFxComponent_C

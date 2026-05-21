local Base = require("NewRoco.Modules.Core.Scene.Component.Buff.Magic.ScenePlayerMagicBaseBuff")
local SceneUtils = require("NewRoco.Modules.Core.Scene.Common.SceneUtils")
local SceneAIUtils = require("NewRoco.AI.SceneAIUtils")
local PlayerModuleEvent = require("NewRoco.Modules.Core.PlayerModule.PlayerModuleEvent")
local ScenePlayerPrepareWindBuff = Base:Extend("ScenePlayerPrepareWindBuff")
local MINI_SPHERE_R = 100
local BASE_RADIUS = 300

function ScenePlayerPrepareWindBuff:OnBegin(owner, MagicInfo)
  Base.OnBegin(self, owner, MagicInfo)
  self.maxThrowDist = _G.DataConfigManager:GetGlobalConfigNumByKeyType("magic_wind_max_throw_distance", _G.DataConfigManager.ConfigTableId.GLOBAL_CONFIG, 2000)
  self.shrinkDist = _G.DataConfigManager:GetGlobalConfigNumByKeyType("magic_wind_shrink_distance", _G.DataConfigManager.ConfigTableId.GLOBAL_CONFIG, 500)
  self.projectDist = _G.DataConfigManager:GetGlobalConfigNumByKeyType("magic_wind_max_project_height", _G.DataConfigManager.ConfigTableId.GLOBAL_CONFIG, 1000)
  local WandData = owner:GetCurWandDataByMagicType(ProtoEnum.SceneMagicType.SMT_WIND)
  self.magicInfo.mozhangBP.DisappearFx = WandData.NS_Wind_Disappead
  self:UpdateWindPos()
  self.errorStr = nil
  self.radius = SceneAIUtils.ParseMagicParamByLevel(self.magicInfo.magicBaseConfig, 0, 0, 0, 4)
  self.lifeTime = SceneAIUtils.ParseMagicParamByLevel(self.magicInfo.magicBaseConfig, 0, 0, 1, 4)
  self.windAcc = SceneAIUtils.ParseMagicParamByLevel(self.magicInfo.magicBaseConfig, 0, 0, 2, 4)
  local markerClass = UE4.UNRCStatics.ResolveClass(UEPath.MARKER_PATH)
  local CurrentWorld = UE4Helper.GetCurrentWorld()
  self.isOnWater = false
  if markerClass and CurrentWorld then
    self.marker = CurrentWorld:Abs_SpawnActor(markerClass)
    self.markerRef = UnLua.Ref(self.marker)
    self.marker:SetActorHiddenInGame(true)
    if WandData and WandData.NS_Wind_Charge then
      local chargeEffectPath = UE.UNRCStatics.GetSoftObjPath(WandData.NS_Wind_Charge)
      if not chargeEffectPath or "" == chargeEffectPath then
        chargeEffectPath = UEPath.DefaultWindChargeEffect
      end
      Log.Debug("Load chargeEffectPath ", chargeEffectPath)
      _G.PlayerResourceManager:LoadResources_PlayerPerform(self, chargeEffectPath, true, self.OnLoadEffectSuccess, self.OnLoadEffectWaterFailed, nil, 10)
      local chargeEffectWaterPath = UE.UNRCStatics.GetSoftObjPath(WandData.NS_Wind_Charge_Water)
      if not chargeEffectWaterPath or "" == chargeEffectWaterPath then
        chargeEffectWaterPath = UEPath.DefaultWindChargeEffectWater
      end
      Log.Debug("Load chargeEffectWaterPath ", chargeEffectWaterPath)
      _G.PlayerResourceManager:LoadResources_PlayerPerform(self, chargeEffectWaterPath, true, self.OnLoadEffectWaterSuccess, self.OnLoadEffectWaterFailed, nil, 10)
    end
  end
  if self.owner.IsMagicReplayActor and self.owner:IsMagicReplayActor() then
  else
    _G.NRCModuleManager:DoCmd(_G.NPCModuleCmd.SendSenseEvent, self.owner:GetActorLocationFrameCache(), Enum.DotsAIWorldEventType.DAWET_MAGIC_WIND_UPLEVEL, nil, 1)
  end
  self.owner:SendEvent(PlayerModuleEvent.ON_CHARGE_VITALITY_BEGIN)
end

function ScenePlayerPrepareWindBuff:OnLoadEffectSuccess(asset)
  if self.marker and self.marker.Effect then
    self.marker.Effect:SetAsset(asset)
  end
end

function ScenePlayerPrepareWindBuff:OnLoadEffectFailed()
  Log.Error("ScenePlayerPrepareWindBuff:OnLoadEffectFailed")
end

function ScenePlayerPrepareWindBuff:OnLoadEffectWaterSuccess(asset)
  if self.marker and self.marker.Effect_Water then
    self.marker.Effect_Water:SetAsset(asset)
  end
end

function ScenePlayerPrepareWindBuff:OnLoadEffectWaterFailed()
  Log.Error("ScenePlayerPrepareWindBuff:OnLoadEffectWaterFailed")
end

function ScenePlayerPrepareWindBuff:OnUpdate(deltaTime)
  Base.OnUpdate(self, deltaTime)
  if self.chargedLevel >= 1 then
    if self.inAimState then
      local level = self.chargedLevel - 1
      self.radius = SceneAIUtils.ParseMagicParamByLevel(self.magicInfo.magicBaseConfig, level, self.currentLevelProcess, 0, 4)
      self.lifeTime = SceneAIUtils.ParseMagicParamByLevel(self.magicInfo.magicBaseConfig, level, self.currentLevelProcess, 1, 4)
      self.windAcc = SceneAIUtils.ParseMagicParamByLevel(self.magicInfo.magicBaseConfig, level, self.currentLevelProcess, 2, 4)
      self.markerScale = self.radius / BASE_RADIUS
      self:FindWindPos3()
    end
  else
    self:UpdateWindPos()
  end
end

function ScenePlayerPrepareWindBuff:UpdateWindPos()
  self.pos = self.owner:GetActorLocation()
  self.pos.Z = self.pos.Z - 80
end

function ScenePlayerPrepareWindBuff:OnCastMagic(...)
  if self.waitCasting then
    return
  end
  if 0 == self.chargedLevel then
    self.magicInfo.mozhangBP:PlayFX(self.magicInfo.mozhangBP.WindLoop0, true)
  end
  Base.OnCastMagic(self, ...)
  self.inAimState = false
end

function ScenePlayerPrepareWindBuff:OnCharged(newChargedLevel)
  if self.owner.isLocal then
    local Id = ProtoEnum.WorldPlayerStatusType.WPST_MAGIC
    local customParams = self.owner.statusComponent._statusParams[Id]
    customParams = customParams or ProtoMessage:newPlayerStatusCustomParams()
    customParams.throw_aim_param.aim_type = ProtoEnum.AimSyncType.AST_MODE_CHANGE
    customParams.throw_aim_param.charged_level = newChargedLevel
    self.owner.statusComponent:RefreshStatus(ProtoEnum.WorldPlayerStatusType.WPST_MAGIC, self.magicInfo.abilityHelper.config.add_status[1], ProtoEnum.WPST_OpCode.WPST_OPCODE_REFRESH, customParams)
  end
  if self.owner.IsMagicReplayActor and self.owner:IsMagicReplayActor() then
  else
    _G.NRCModuleManager:DoCmd(_G.NPCModuleCmd.SendSenseEvent, self.owner:GetActorLocationFrameCache(), Enum.DotsAIWorldEventType.DAWET_MAGIC_WIND_UPLEVEL, nil, self.chargedLevel + 1)
  end
  if 1 == newChargedLevel then
    self.magicInfo.mozhangBP:DelayPlayFX(self.magicInfo.mozhangBP.WindLoop1, 0.65, true)
    self.magicInfo.mozhangBP:PlayFX(self.magicInfo.mozhangBP.WindLoop1Start, true)
  end
  if 2 == newChargedLevel then
    self.owner:SendEvent(PlayerModuleEvent.ON_CHARGE_VITALITY_FULL)
  end
end

function ScenePlayerPrepareWindBuff:FindWindPos1()
  local cameraManager = self.owner:GetUEController().PlayerCameraManager
  local rayStart = cameraManager:Abs_GetCameraLocation()
  local rayDirection = cameraManager:GetCameraRotation():ToVector()
  local rayEnd = rayStart + rayDirection * 10000
  local traceChannel = {
    UE4.ECollisionChannel.ECC_WorldStatic
  }
  local ignoreActors = UE4.TArray(UE.AActor)
  ignoreActors:Add(cameraManager)
  ignoreActors:Add(self.owner.viewObj)
  local ownerLocation = self.owner.viewObj:Abs_K2_GetActorLocation()
  ownerLocation.Z = ownerLocation.Z - 80
  local hitResults, isHit = UE4.UKismetSystemLibrary.Abs_LineTraceMultiForObjects(_G.UE4Helper.GetCurrentWorld(), rayStart, rayEnd, traceChannel, false, ignoreActors, 0)
  local distance = 2000
  if isHit then
    local hitResult = self:GetLandscapeHit(hitResults)
    if hitResult.bBlockingHit then
      local hitLocation = UE4.FVector(hitResult.Location.X, hitResult.Location.Y, hitResult.Location.Z)
      local offset = hitLocation - ownerLocation
      distance = offset:Size2D()
      distance = math.clamp(distance, 200, 2000)
    end
  end
  rayDirection.Z = 0
  local validLocation = ownerLocation + rayDirection * distance
  local ZOffset = UE4.FVector(0, 0, 1000)
  rayStart = validLocation + ZOffset
  rayEnd = validLocation - ZOffset
  local tryNum = 0
  while not self:GetCeilPos(rayStart, rayEnd) and tryNum < 20 and distance > 0 do
    distance = math.max(0, distance - 10)
    tryNum = tryNum + 1
    rayEnd = ownerLocation + rayDirection * distance - ZOffset
  end
  if self.pos then
    if self.marker then
      self.marker:SetActorHiddenInGame(false)
      self.marker:Abs_K2_SetActorLocation_WithoutHit(self.pos)
    end
  else
    self.marker:SetActorHiddenInGame(true)
  end
end

function ScenePlayerPrepareWindBuff:GetCeilPos(rayStart, rayEnd)
  local traceChannel = {
    UE4.ECollisionChannel.ECC_WorldStatic
  }
  local ignoreActors = UE4.TArray(UE.AActor)
  local cameraManager = self.owner:GetUEController().PlayerCameraManager
  ignoreActors:Add(cameraManager)
  ignoreActors:Add(self.owner.viewObj)
  local hitResults, isHit = UE4.UKismetSystemLibrary.Abs_CapsuleTraceMultiForObjects(_G.UE4Helper.GetCurrentWorld(), rayStart, rayEnd, 150, 200, traceChannel, false, ignoreActors, 0)
  if isHit then
    local hitResult, isWater = self:GetLandscapeHit(hitResults)
    if hitResult then
      if math.abs(hitResult.ImpactNormal.Z) > 0.5 then
        self.pos = hitResult.ImpactPoint
        self.posNormal = hitResult.ImpactNormal
        self.isOnWater = isWater
        return true
      else
      end
      self.errorStr = nil
    end
  end
  return false
end

function ScenePlayerPrepareWindBuff:OnFinish(param)
  if UE.UObject.IsValid(self.marker) then
    self.marker:SetActorHiddenInGame(true)
    self.marker:K2_DestroyActor()
    self.marker = nil
  end
  self.markerRef = nil
  Base.OnFinish(self, param)
end

function ScenePlayerPrepareWindBuff:GetLandscapeHit(hitResults)
  local hitResult
  for i = 1, hitResults:Length() do
    hitResult = hitResults:Get(i)
    local isWater, isPlaceable = UE4.URocoPlayerBlueprintFunctionLibrary.IsHitWindPlaceable(hitResult)
    if isPlaceable then
      return hitResult, isWater
    end
  end
  return nil, false
end

function ScenePlayerPrepareWindBuff:FindWindPos3()
  self.pos = UE.URocoPlayerBlueprintFunctionLibrary.FindWindPos(self.owner.viewObj, self.radius, self.projectDist, self.maxThrowDist, self.shrinkDist)
  if self.pos then
    if self.marker then
      self.marker:SetActorHiddenInGame(false)
      self.marker:Abs_K2_SetActorLocation_WithoutHit(self.pos)
      self.marker:SetActorRelativeScale3D(_G.FVectorOne * self.markerScale)
      self.marker:SetIsOnWater(self.isOnWater)
    end
  else
    self.marker:SetActorHiddenInGame(true)
  end
end

function ScenePlayerPrepareWindBuff:FindWindPos2()
  local cameraManager = self.owner:GetUEController().PlayerCameraManager
  local rayStart = cameraManager:Abs_GetCameraLocation()
  local rayDirection = cameraManager:GetCameraRotation():ToVector()
  local rayEnd = rayStart + rayDirection * 10000
  local traceChannel = UE4.ECollisionChannel.ECC_WorldStatic
  local ignoreActors = UE4.TArray(UE.AActor)
  ignoreActors:Add(cameraManager)
  ignoreActors:Add(self.owner.viewObj)
  local ownerLocation = self.owner.viewObj:Abs_K2_GetActorLocation()
  ownerLocation.Z = ownerLocation.Z - 80
  local hitResult, isHit = UE4.UKismetSystemLibrary.Abs_LineTraceSingle(_G.UE4Helper.GetCurrentWorld(), rayStart, rayEnd, traceChannel, false, ignoreActors, 0)
  local distance = 2000
  if isHit and hitResult.bBlockingHit then
    local hitLocation = UE4.FVector(hitResult.Location.X, hitResult.Location.Y, hitResult.Location.Z)
    local offset = hitLocation - ownerLocation
    distance = offset:Size2D()
    distance = math.clamp(distance, 200, 2000)
  end
  rayDirection.Z = 0
  local validLocation = ownerLocation + rayDirection * distance
  local ZOffset = UE4.FVector(0, 0, 1000)
  rayStart = validLocation + ZOffset
  rayEnd = validLocation - ZOffset
  local tryNum = 0
  while not self:GetCeilPos2(rayStart, rayEnd, ownerLocation) and tryNum < 20 and distance > 0 do
    distance = math.max(0, distance - 50)
    tryNum = tryNum + 1
    rayEnd = ownerLocation + rayDirection * distance - ZOffset
  end
  if self.pos then
    if self.marker then
      self.marker:SetActorHiddenInGame(false)
      self.marker:Abs_K2_SetActorLocation_WithoutHit(self.pos)
      self.marker:SetActorRelativeScale3D(_G.FVectorOne * self.markerScale)
      self.marker:SetIsOnWater(self.isOnWater)
    end
  else
    self.marker:SetActorHiddenInGame(true)
  end
end

function ScenePlayerPrepareWindBuff:GetCeilPos2(rayStart, rayEnd, ownerLocation)
  local cameraManager = self.owner:GetUEController().PlayerCameraManager
  local waterObjectType = UE4.UNRCStatics.ConvertToObjectType(UE4.ECollisionChannel.ECC_GameTraceChannel13)
  local traceChannel = {
    UE.EObjectTypeQuery.WorldStatic,
    waterObjectType
  }
  local ignoreActors = UE4.TArray(UE.AActor)
  ignoreActors:Add(cameraManager)
  ignoreActors:Add(self.owner.viewObj)
  local hitResults, isHit = UE4.UKismetSystemLibrary.Abs_LineTraceMultiForObjects(_G.UE4Helper.GetCurrentWorld(), rayStart, rayEnd, traceChannel, false, ignoreActors, 0)
  if isHit then
    local hitResult, isWater = self:GetLandscapeHit(hitResults)
    if hitResult and hitResult.bBlockingHit then
      local hitLocation = UE4.FVector(hitResult.Location.X, hitResult.Location.Y, hitResult.Location.Z)
      local direction = hitLocation - ownerLocation
      direction:Normalize()
      local isBlock = self:SphereMatrixBlockTest(UE.FVector(hitLocation.X, hitLocation.Y, hitLocation.Z), direction)
      if not isBlock then
        self.pos = hitLocation
        self.isOnWater = isWater
        return true
      end
    end
  end
  return false
end

function ScenePlayerPrepareWindBuff:SphereMatrixBlockTest(location, direction)
  location.Z = location.Z + 50
  local radius = 100
  local hits = 0
  local traces = 0
  local cameraManager = self.owner:GetUEController().PlayerCameraManager
  local traceChannel = UE4.ECollisionChannel.ECC_WorldStatic
  local ignoreActors = UE4.TArray(UE.AActor)
  ignoreActors:Add(cameraManager)
  ignoreActors:Add(self.owner.viewObj)
  local rotator = direction:ToRotator()
  for i = 1, 5 do
    local newX = 0
    if i < 3 then
      newX = -i * radius
    else
      newX = (i - 3) * radius
    end
    for j = 0, 2 do
      local newZ = j * radius
      local offsetLocation = rotator:GetRightVector() * newX
      offsetLocation.Z = newZ
      local newLocation = location + offsetLocation
      local hitResult, isHit = UE4.UKismetSystemLibrary.Abs_SphereTraceSingle(_G.UE4Helper.GetCurrentWorld(), newLocation, newLocation + direction * 50, 50, traceChannel, false, ignoreActors, 0)
      traces = traces + 1
      if isHit and hitResult.bBlockingHit then
        hits = hits + 1
      end
    end
  end
  local hitsPercent = hits / traces
  return hitsPercent > 0.6
end

function ScenePlayerPrepareWindBuff:FVectorStr(inVector)
  return string.format("%f:%f:%f", inVector.X, inVector.Y, inVector.Z)
end

return ScenePlayerPrepareWindBuff

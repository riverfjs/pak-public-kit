local NPCModuleEvent = require("NewRoco.Modules.Core.NPC.NPCModuleEvent")
local SceneUtils = require("NewRoco.Modules.Core.Scene.Common.SceneUtils")
local MagicMessageUtils = Class()
local UpLandTraceExtent = 200.0
local LandTraceExtent = 10000.0
local ShowTrajectory = false
local BlackList = _G.DataConfigManager:GetGlobalConfigByKey("mark_ban_npc_blacklist").numList
MagicMessageUtils.NpcValidType = {
  UnInited = -2,
  Invalid = -1,
  Valid = 0,
  TooHigh = 3,
  Planeness_NoLand = 6,
  Water = 4,
  Overlap = 10,
  OverlapNotLoaded = 11,
  AirWall = 30,
  Normal = 100,
  OnIllegal = 5
}

function MagicMessageUtils.TryGetLocalizationMessage(id, default)
  if nil == id then
    return default
  end
  local conf = _G.DataConfigManager:GetLocalizationConf(id)
  if nil ~= conf then
    return conf.msg
  end
  return default
end

function MagicMessageUtils.GetInvalidReason(type)
  if type == MagicMessageUtils.NpcValidType.Planeness_NoLand then
    return MagicMessageUtils.TryGetLocalizationMessage("TryCastMagic_Create_Planeness", "")
  elseif type == MagicMessageUtils.NpcValidType.Overlap then
    return MagicMessageUtils.TryGetLocalizationMessage("magic_message_bad_location", "")
  elseif type == MagicMessageUtils.NpcValidType.OverlapNotLoaded then
    return MagicMessageUtils.TryGetLocalizationMessage("TryCastMagic_Create_FetchingNpc", "")
  elseif type == MagicMessageUtils.NpcValidType.AirWall then
    return MagicMessageUtils.TryGetLocalizationMessage("TryCastMagic_Create_AirWall", "")
  elseif type == MagicMessageUtils.NpcValidType.Invalid then
    return ""
  elseif type == MagicMessageUtils.NpcValidType.TooHigh then
    return MagicMessageUtils.TryGetLocalizationMessage("Error_Code_50040", "")
  elseif type == MagicMessageUtils.NpcValidType.UnInited then
    return MagicMessageUtils.TryGetLocalizationMessage("mark_magic_message_not_ready", "")
  elseif type == MagicMessageUtils.NpcValidType.OnIllegal then
    return MagicMessageUtils.TryGetLocalizationMessage("mark_message_move_plate", "")
  end
  return nil
end

function MagicMessageUtils.GetVideoInvalidReason(type)
  if type == MagicMessageUtils.NpcValidType.Planeness_NoLand then
    return MagicMessageUtils.TryGetLocalizationMessage("TryCastMagic_Create_Planeness", "")
  elseif type == MagicMessageUtils.NpcValidType.Overlap then
    return MagicMessageUtils.TryGetLocalizationMessage("mark_video_bad_location", "")
  elseif type == MagicMessageUtils.NpcValidType.OverlapNotLoaded then
    return MagicMessageUtils.TryGetLocalizationMessage("TryCastMagic_Create_FetchingNpc", "")
  elseif type == MagicMessageUtils.NpcValidType.AirWall then
    return MagicMessageUtils.TryGetLocalizationMessage("TryCastMagic_Create_AirWall", "")
  elseif type == MagicMessageUtils.NpcValidType.Invalid then
    return ""
  elseif type == MagicMessageUtils.NpcValidType.TooHigh then
    return MagicMessageUtils.TryGetLocalizationMessage("Error_Code_50040", "")
  elseif type == MagicMessageUtils.NpcValidType.UnInited then
    return MagicMessageUtils.TryGetLocalizationMessage("mark_magic_message_not_ready", "")
  elseif type == MagicMessageUtils.NpcValidType.OnIllegal then
    return MagicMessageUtils.TryGetLocalizationMessage("mark_video_move_plate", "")
  end
  return nil
end

function MagicMessageUtils.SetTrajectory(ShouldShow)
  ShowTrajectory = ShouldShow
end

function MagicMessageUtils.TryGetGlobalConfig(tableId, key, member, default)
  local value = _G.DataConfigManager:GetGlobalConfigByKeyType(key, tableId)
  if value and value[member] then
    return value[member]
  end
  return default
end

function MagicMessageUtils.GetNpcRefreshContentConf(magicInfo)
  local effectStruct = magicInfo.magicBaseConfig.effect_struct
  if nil == effectStruct or #effectStruct <= 0 then
    Log.Error("magicInfo.magicBaseConfig.effect_struct is nil or empty")
    return nil
  end
  local param = effectStruct[1].effect_params_1
  if nil == param or #param <= 0 then
    Log.Error("effectStruct[1].effect_params1 is nil or empty")
    return nil
  end
  return param[1]
end

function MagicMessageUtils.GetCreateMessageMaxCount(magicInfo)
  local effectStruct = magicInfo.magicBaseConfig.effect_struct
  if nil == effectStruct or #effectStruct <= 0 then
    Log.Error("magicInfo.magicBaseConfig.effect_struct is nil or empty")
    return nil
  end
  local param = effectStruct[1].effect_params_2
  if nil == param or #param <= 0 then
    Log.Error("effectStruct[1].effect_params2 is nil or empty")
    return nil
  end
  return param[1]
end

function MagicMessageUtils.NpcSnapToGround(npc, SnapFlag)
  if not npc then
    return
  end
  local viewObj = npc.viewObj
  if not viewObj then
    return
  end
  local IsVideo = npc.config.id == 55591
  local waterInfo = MagicMessageUtils.GetWaterInfo(viewObj:K2_GetActorLocation())
  local landInfo = MagicMessageUtils.GetLandInfo(viewObj:K2_GetActorLocation())
  if landInfo and waterInfo and landInfo.position and waterInfo.position then
    if landInfo.position.Z < waterInfo.position.Z then
      landInfo = waterInfo
    end
  elseif nil == landInfo then
    landInfo = waterInfo
  end
  if nil ~= landInfo and landInfo.position and landInfo.position.Z then
    local tempPos = {
      viewObj:K2_GetActorLocation().X,
      viewObj:K2_GetActorLocation().Y,
      viewObj:K2_GetActorLocation().Z
    }
    if IsVideo then
      landInfo.position.Z = landInfo.position.Z + 40
      if viewObj:K2_GetActorLocation().Z <= landInfo.position.Z + 20 then
        tempPos = {
          X = landInfo.position.X,
          Y = landInfo.position.Y,
          Z = landInfo.position.Z + 20
        }
        SnapFlag = true
      end
    else
      landInfo.position.Z = landInfo.position.Z + 20
      if viewObj:K2_GetActorLocation().Z <= landInfo.position.Z then
        SnapFlag = true
      end
    end
    if SnapFlag then
      if IsVideo then
        npc:SetActorLocation(SceneUtils.ConvertRelativeToAbsolute(tempPos))
      else
        npc:SetActorLocation(SceneUtils.ConvertRelativeToAbsolute(landInfo.position))
      end
    end
    if viewObj.SetPosition then
      viewObj:SetPosition(viewObj:K2_GetActorLocation(), landInfo.position)
    end
  end
end

function MagicMessageUtils.GetNpcLandInfo(npc)
  if not npc then
    return
  end
  local viewObj = npc.viewObj
  if not viewObj then
    return
  end
  local waterInfo = MagicMessageUtils.GetWaterInfo(viewObj:K2_GetActorLocation())
  local landInfo = MagicMessageUtils.GetLandInfo(viewObj:K2_GetActorLocation())
  if landInfo and waterInfo then
    if landInfo.position.Z < waterInfo.position.Z then
      landInfo = waterInfo
    end
  elseif nil == landInfo then
    landInfo = waterInfo
  end
  if nil ~= landInfo then
    return math.floor(landInfo.position.Z)
  end
end

function MagicMessageUtils.FlowerSnapToGround(npc)
  if not npc then
    return
  end
  local viewObj = npc.viewObj
  if not viewObj then
    return
  end
  local type = MagicMessageUtils.NpcValidType.Valid
  local waterInfo = MagicMessageUtils.GetWaterInfo(viewObj:K2_GetActorLocation())
  local landInfo = MagicMessageUtils.GetLandInfo(viewObj:K2_GetActorLocation())
  if landInfo and waterInfo then
    if landInfo.position.Z < waterInfo.position.Z then
      landInfo = waterInfo
      type = MagicMessageUtils.NpcValidType.Water
    end
  elseif nil == landInfo then
    landInfo = waterInfo
    type = MagicMessageUtils.NpcValidType.Water
  end
  if nil ~= landInfo then
    landInfo.position.Z = landInfo.position.Z - 20
    npc:SetActorLocation(SceneUtils.ConvertRelativeToAbsolute(landInfo.position))
  elseif npc.serverData.MagicFeedInfo then
    MagicMessageUtils.DeleteLocalNpc(npc)
    local MagicFeedInfo = npc.serverData.MagicFeedInfo
    if MagicFeedInfo and MagicFeedInfo.grid_id and MagicFeedInfo.feed_id then
      _G.NRCModuleManager:DoCmd(_G.MagicMessageModuleCmd.DeleteNpcByGridAndFeedId, MagicFeedInfo.grid_id, MagicFeedInfo.feed_id, _G.ProtoEnum.MarkGameplay.MK_MAGIC_FLOWER)
    end
  end
  return type
end

function MagicMessageUtils.GetActorBounds(viewObj)
  local Comps = viewObj:K2_GetComponentsByClass(UE.UMeshComponent)
  local allMin, allMax
  for _, Comp in tpairs(Comps) do
    if not Comp:IsA(UE.URocoWidgetComponent) then
      local origin = UE4.FVector(0, 0, 0)
      local extent = UE4.FVector(0, 0, 0)
      local radius = 0
      UE4.UKismetSystemLibrary.GetComponentBounds(Comp, origin, extent, radius)
      local min = origin - extent
      local max = origin + extent
      if nil == allMin then
        allMin = UE.FVector(min.X, min.Y, min.Z)
      else
        allMin.X = math.min(allMin.X, min.X)
        allMin.Y = math.min(allMin.Y, min.Y)
        allMin.Z = math.min(allMin.Z, min.Z)
      end
      if nil == allMax then
        allMax = UE.FVector(max.X, max.Y, max.Z)
      else
        allMax.X = math.max(allMax.X, max.X)
        allMax.Y = math.max(allMax.Y, max.Y)
        allMax.Z = math.max(allMax.Z, max.Z)
      end
    end
  end
  local allOrigin, allExtent
  if nil == allMin and nil == allMin then
    allOrigin = viewObj:K2_GetActorLocation()
    if nil ~= viewObj.BoundingRadius then
      allExtent = UE.FVector(viewObj.BoundingRadius, viewObj.BoundingRadius, 0)
    else
      allExtent = UE.FVector(0, 0, 0)
    end
  else
    allOrigin = (allMax + allMin) / 2.0
    allExtent = (allMax - allMin) / 2.0
  end
  return allOrigin, allExtent
end

function MagicMessageUtils.GetWaterInfo(targetLocation)
  local startLocation = UE.FVector(targetLocation.X, targetLocation.Y, targetLocation.Z + UpLandTraceExtent)
  if not targetLocation.Z then
    Log.Error("targetLocation.Z is nil")
  end
  local endLocation = UE.FVector(targetLocation.X, targetLocation.Y, targetLocation.Z - LandTraceExtent)
  local channel = UE.ETraceTypeQuery.Water
  local hitResults, bSuccess = UE4.UKismetSystemLibrary.LineTraceMulti(_G.UE4Helper.GetCurrentWorld(), startLocation, endLocation, channel, true, nil)
  if bSuccess then
    local landInfo = {}
    for i = 1, hitResults:Length() do
      local hitResult = hitResults:Get(i)
      if hitResult.Actor and hitResult.Actor:IsA(UE.ATriggerBase) then
      elseif landInfo.position == nil or landInfo.position.Z < hitResult.ImpactPoint.Z then
        landInfo.position = UE4.FVector(hitResult.ImpactPoint.X, hitResult.ImpactPoint.Y, hitResult.ImpactPoint.Z)
      end
    end
    return landInfo
  end
  return nil
end

function MagicMessageUtils.GetLandInfo(targetLocation)
  local startLocation = UE.FVector(targetLocation.X, targetLocation.Y, targetLocation.Z + UpLandTraceExtent)
  local endLocation = UE.FVector(targetLocation.X, targetLocation.Y, targetLocation.Z - LandTraceExtent)
  local channel = UE4.UNRCStatics.ConvertToTraceChannel(UE4.ECollisionChannel.ECC_GameTraceChannel5)
  local hitResults, bSuccess = UE4.UKismetSystemLibrary.LineTraceMulti(_G.UE4Helper.GetCurrentWorld(), startLocation, endLocation, channel, true, nil)
  if bSuccess then
    local landInfo = {}
    for i = 1, hitResults:Length() do
      local hitResult = hitResults:Get(i)
      if hitResult.Actor and hitResult.Actor:IsA(UE.ATriggerBase) then
      elseif landInfo.position == nil or landInfo.position.Z < hitResult.ImpactPoint.Z then
        landInfo.position = UE4.FVector(hitResult.ImpactPoint.X, hitResult.ImpactPoint.Y, hitResult.ImpactPoint.Z + 20)
      end
    end
    return landInfo
  end
  return nil
end

function MagicMessageUtils.GetWaterHeight(targetLocation)
  if not targetLocation then
    return nil
  end
  local startLocation = UE.FVector(targetLocation.X, targetLocation.Y, targetLocation.Z + LandTraceExtent)
  local endLocation = UE.FVector(targetLocation.X, targetLocation.Y, targetLocation.Z - LandTraceExtent)
  local waterTraceChannel = UE.ETraceTypeQuery.Water
  local hitResult, bSuccess = UE4.UKismetSystemLibrary.LineTraceSingle(_G.UE4Helper.GetCurrentWorld(), startLocation, endLocation, waterTraceChannel, false, nil, 0)
  if bSuccess then
    return hitResult.ImpactPoint.Z
  end
  return nil
end

function MagicMessageUtils.CheckAirWallNearby(npc, additionalDistance)
  if nil == npc then
    return false
  end
  if nil == additionalDistance then
    additionalDistance = 0
  end
  local localPlayer = _G.NRCModuleManager:DoCmd(_G.PlayerModuleCmd.GET_LOCAL_PLAYER)
  local playerPos = localPlayer:GetActorLocation()
  local npcPos = npc:GetActorLocation()
  npcPos.Z = playerPos.Z
  local _, extent = MagicMessageUtils.GetActorBounds(npc.viewObj)
  local radius = math.max(extent.X, extent.Y)
  local traceChannel = UE4.UNRCStatics.ConvertToTraceChannel(UE4.ECollisionChannel.ECC_GameTraceChannel14)
  local actorsToIgnore = {}
  if nil ~= localPlayer then
    table.insert(actorsToIgnore, localPlayer.viewObj)
  end
  table.insert(actorsToIgnore, npc.viewObj)
  local hitResults, _ = UE4.UKismetSystemLibrary.Abs_SphereTraceMulti(_G.UE4Helper.GetCurrentWorld(), npcPos, npcPos + UE4.FVector(0, 0, 0.1), radius + additionalDistance, traceChannel, false, actorsToIgnore, nil, nil, false, nil, nil, nil)
  
  local function checkIsAirWall(hitResult)
    local component = hitResult.Component
    if not component:IsA(UE4.UProceduralMeshComponent) then
      return false
    end
    local collisionEnabled = component:GetCollisionEnabled()
    if collisionEnabled == UE4.ECollisionEnabled.QueryOnly then
      return false
    end
    local response = component:GetCollisionResponseToChannel(UE4.ECollisionChannel.ECC_GameTraceChannel14)
    if response == UE.ECollisionResponse.ECR_Ignore then
      return false
    end
    return true
  end
  
  for _, hitResult in tpairs(hitResults) do
    if checkIsAirWall(hitResult) then
      if _G.NRCModuleManager:DoCmd(_G.MagicMessageModuleCmd.GetCanDrawDebug) and hitResult.Component then
        local duration = 0.03333333333333333
        UE4.UKismetSystemLibrary.Abs_DrawDebugPoint(_G.UE4Helper.GetCurrentWorld(), hitResult.ImpactPoint, 10.0, UE4.FLinearColor(1, 0.9, 0, 1), duration)
        UE4.UKismetSystemLibrary.Abs_DrawDebugString(_G.UE4Helper.GetCurrentWorld(), hitResult.ImpactPoint, UE4.UKismetSystemLibrary.GetDisplayName(hitResult.Component), nil, UE4.FLinearColor(1, 0.8, 0, 1), duration)
      end
      return true
    end
  end
  return false
end

function MagicMessageUtils.CheckOnIllegal(targetLocation)
  if nil == BlackList or nil == next(BlackList) then
    return false
  end
  local landInfo = MagicMessageUtils.GetLandInfo(targetLocation)
  local landHeight
  if landInfo and landInfo.position then
    landHeight = landInfo.position.Z
  end
  local waterInfo = MagicMessageUtils.GetWaterInfo(targetLocation)
  local waterHeight
  if waterInfo and waterInfo.position then
    waterHeight = waterInfo.position.Z
  end
  local duration = 0.03333333333333333
  local startLocation = UE.FVector(targetLocation.X, targetLocation.Y, targetLocation.Z + UpLandTraceExtent)
  local endLocation = UE.FVector(targetLocation.X, targetLocation.Y, targetLocation.Z - LandTraceExtent)
  local channel1 = UE4.UNRCStatics.ConvertToTraceChannel(UE4.ECollisionChannel.ECC_GameTraceChannel5)
  local channel2 = UE4.UNRCStatics.ConvertToTraceChannel(UE4.ECollisionChannel.ECC_GameTraceChannel2)
  local hitResult1, bSuccess1 = UE4.UKismetSystemLibrary.LineTraceMulti(_G.UE4Helper.GetCurrentWorld(), startLocation, endLocation, channel1, true, nil)
  local hitResult2, bSuccess2 = UE4.UKismetSystemLibrary.LineTraceMulti(_G.UE4Helper.GetCurrentWorld(), startLocation, endLocation, channel2, true, nil)
  local value
  if landHeight and waterHeight then
    if landHeight > waterHeight then
      value = hitResult1
    else
      value = hitResult2
    end
  elseif landHeight then
    value = hitResult1
  elseif waterHeight then
    value = hitResult2
  end
  if (bSuccess1 or bSuccess2) and value then
    for i = 1, value:Length() do
      local hitResult = value:Get(i)
      if hitResult.Actor and hitResult.Actor:IsA(UE.ATriggerBase) then
      else
        if hitResult.Actor:IsA(UE.ANPCSceneSkeletalMeshActor) or hitResult.Actor:IsA(UE.ANRCSceneMoveMeshActor) then
          if ShowTrajectory then
            UE4.UKismetSystemLibrary.DrawDebugString(_G.UE4Helper.GetCurrentWorld(), hitResult.ImpactPoint, "\228\184\141\229\144\136\230\179\149\229\156\176\229\157\151", nil, UE4.FLinearColor(1, 1, 0, 1), duration)
          end
          return true
        end
        if hitResult.Actor:IsValid() and hitResult.Actor.sceneCharacter and hitResult.Actor.sceneCharacter.config then
          local characterId = hitResult.Actor.sceneCharacter.config.id
          for _, v in pairs(BlackList) do
            if characterId == v then
              if ShowTrajectory then
                UE4.UKismetSystemLibrary.DrawDebugString(_G.UE4Helper.GetCurrentWorld(), hitResult.ImpactPoint, "\228\184\141\229\144\136\230\179\149\229\156\176\229\157\151", nil, UE4.FLinearColor(1, 1, 0, 1), duration)
              end
              return true
            end
          end
        end
      end
    end
  end
  return false
end

function MagicMessageUtils.CheckOverlap(npc, center, extent, actorsToIgnore, duration)
  if nil == npc then
    return false
  end
  if not npc.viewObj then
    return false
  end
  if nil == center or nil == extent then
    center, extent = MagicMessageUtils.GetActorBounds(npc.viewObj)
  end
  if 0 == extent.Z then
    extent.Z = 20.0
    center.Z = center.Z + extent.Z
  end
  center.Z = center.Z + 10.0
  local radius = math.max(extent.X, extent.Y) + 30.0
  if nil == actorsToIgnore then
    actorsToIgnore = {}
  end
  local localPlayer = _G.NRCModuleManager:DoCmd(_G.PlayerModuleCmd.GET_LOCAL_PLAYER)
  if nil ~= localPlayer then
    table.insert(actorsToIgnore, localPlayer.viewObj)
  end
  table.insert(actorsToIgnore, npc.viewObj)
  if npc.viewObj.NRCChildActor then
    table.insert(actorsToIgnore, npc.viewObj.NRCChildActor:GetChildActor())
  end
  if nil == duration then
    duration = 0.03333333333333333
  end
  local traceObjectTypes = {
    UE4.EObjectTypeQuery.WorldDynamic,
    UE4.EObjectTypeQuery.WorldStatic,
    UE4.EObjectTypeQuery.Pawn,
    UE4.EObjectTypeQuery.Character,
    UE4.EObjectTypeQuery.Tree
  }
  local drawDebugType = UE4.EDrawDebugTrace.None
  local traceColor, traceHitColor
  if ShowTrajectory then
    drawDebugType = UE4.EDrawDebugTrace.ForOneFrame
    traceColor = UE4.FLinearColor(0.0, 1.0, 0.0, 1.0)
    traceHitColor = UE4.FLinearColor(1.0, 0.0, 0.0, 1.0)
  end
  local hitResults = UE4.UKismetSystemLibrary.SphereTraceMultiForObjects(_G.UE4Helper.GetCurrentWorld(), center, center, radius + 20, traceObjectTypes, false, actorsToIgnore, drawDebugType, nil, false, traceColor, traceHitColor, 2.0)
  
  local function judgeHitResult(hitResult)
    if not hitResult or not hitResult.bBlockingHit then
      return false
    end
    local comp = hitResult.Component
    if not comp then
      return false
    end
    local position = hitResult.ImpactPoint
    if not position then
      return false
    end
    local collisionEnabled = comp:GetCollisionEnabled()
    if collisionEnabled == UE4.ECollisionEnabled.QueryOnly then
      if hitResult.Actor and hitResult.Actor.BoundingRadius then
        return true
      end
      local response = comp:GetCollisionResponseToChannel(UE4.ECollisionChannel.ECC_GameTraceChannel17)
      if response ~= UE.ECollisionResponse.ECR_Ignore then
        return true
      end
      if hitResult.Actor:IsA(UE4.ARocoReplicateCharacter) then
        return true
      end
      return false
    end
    return true
  end
  
  for _, hitResult in tpairs(hitResults) do
    if judgeHitResult(hitResult) then
      if ShowTrajectory then
        UE4.UKismetSystemLibrary.DrawDebugString(_G.UE4Helper.GetCurrentWorld(), hitResult.ImpactPoint, UE4.UKismetSystemLibrary.GetDisplayName(hitResult.Component), nil, UE4.FLinearColor(1, 1, 0, 1), duration)
      end
      return true
    end
  end
  local lineCheckNUm = 6
  local angleUnit = 360 / lineCheckNUm
  local lineTraceChannel = {
    UE4.ECollisionChannel.ECC_WorldStatic,
    UE4.ECollisionChannel.ECC_WorldDynamic,
    UE4.ECollisionChannel.ECC_Pawn
  }
  for idx = 1, lineCheckNUm do
    local angle = idx * angleUnit
    local radian = angle * math.pi / 180
    local endPosition = UE4.FVector(center.X + radius * math.cos(radian), center.Y + radius * math.sin(radian), center.Z)
    local lineResults, _ = UE4.UKismetSystemLibrary.LineTraceMultiForObjects(_G.UE4Helper.GetCurrentWorld(), center, endPosition, lineTraceChannel, false, actorsToIgnore, drawDebugType, nil, false, traceColor, traceHitColor, nil)
    for _, hitResult in tpairs(lineResults) do
      if judgeHitResult(hitResult) then
        if ShowTrajectory then
          UE4.UKismetSystemLibrary.DrawDebugString(_G.UE4Helper.GetCurrentWorld(), hitResult.ImpactPoint, UE4.UKismetSystemLibrary.GetDisplayName(hitResult.Component), nil, UE4.FLinearColor(1, 1, 0, 1), duration)
        end
        return true
      end
    end
  end
  local viewObj = npc.viewObj
  local npcPosition = viewObj:K2_GetActorLocation()
  local WaterInfo = MagicMessageUtils.GetWaterInfo(npcPosition)
  local DryInfo = MagicMessageUtils.GetLandInfo(npcPosition)
  local landInfo
  if WaterInfo and DryInfo then
    if WaterInfo.position.Z > DryInfo.position.Z then
      landInfo = WaterInfo
    else
      landInfo = DryInfo
    end
  elseif nil == WaterInfo then
    landInfo = DryInfo
  elseif nil == DryInfo then
    landInfo = WaterInfo
  end
  if nil == landInfo then
    return true
  end
  local downRayLength = npcPosition.Z - landInfo.position.Z
  local downEndPosition = UE4.FVector(center.X, center.Y, center.Z - downRayLength)
  local downRayResults, _ = UE4.UKismetSystemLibrary.LineTraceMultiForObjects(_G.UE4Helper.GetCurrentWorld(), center, downEndPosition, lineTraceChannel, false, actorsToIgnore, drawDebugType, nil, false, traceColor, traceHitColor, nil)
  for _, hitResult in tpairs(downRayResults) do
    if judgeHitResult(hitResult) then
      if ShowTrajectory then
        UE4.UKismetSystemLibrary.DrawDebugString(_G.UE4Helper.GetCurrentWorld(), hitResult.ImpactPoint, UE4.UKismetSystemLibrary.GetDisplayName(hitResult.Component), nil, UE4.FLinearColor(1, 1, 0, 1), duration)
      end
      return true
    end
  end
  local centerPosition = npc.viewObj:Abs_K2_GetActorLocation()
  centerPosition = UE4.FVector(centerPosition.X, centerPosition.Y, centerPosition.Z + 20)
  if localPlayer then
    local playerPosition = localPlayer.viewObj:Abs_K2_GetActorLocation()
    if playerPosition then
      local lineResults, LandSuccess = UE.UKismetSystemLibrary.Abs_LineTraceSingle(_G.UE4Helper.GetCurrentWorld(), centerPosition, playerPosition, UE.ETraceTypeQuery.Visibility, false, actorsToIgnore, drawDebugType, nil, false, traceColor, traceHitColor, nil)
      if LandSuccess and judgeHitResult(lineResults) then
        if ShowTrajectory then
          UE4.UKismetSystemLibrary.DrawDebugString(_G.UE4Helper.GetCurrentWorld(), centerPosition, UE4.UKismetSystemLibrary.GetDisplayName(lineResults.Component), nil, traceHitColor, duration)
        end
        return true
      end
      local lineResult, LandSuccessSec = UE.UKismetSystemLibrary.Abs_LineTraceSingle(_G.UE4Helper.GetCurrentWorld(), playerPosition, centerPosition, UE.ETraceTypeQuery.Visibility, false, actorsToIgnore, drawDebugType, nil, false, traceColor, traceHitColor, nil)
      if LandSuccessSec and judgeHitResult(lineResult) then
        if ShowTrajectory then
          UE4.UKismetSystemLibrary.DrawDebugString(_G.UE4Helper.GetCurrentWorld(), centerPosition, UE4.UKismetSystemLibrary.GetDisplayName(lineResult.Component), nil, traceHitColor, duration)
        end
        return true
      end
    end
  end
  return false
end

function MagicMessageUtils.CheckOverlapNotLoadedCapsule(origin, extent, npc)
  if not npc then
    return false
  end
  local targetPosition = npc:GetServerPosition()
  local targetScale = npc:GetConfigScale()
  local targetRadius = (npc.modelConf.capsule_radius / 1000.0 or 0) * targetScale
  local targetHalfHeight = (npc.modelConf.capsule_halfheight / 1000.0 or 0) * targetScale
  local targetOrigin = UE4.FVector(targetPosition.x, targetPosition.y, targetPosition.z + targetHalfHeight)
  local spawnTransform = UE4.FTransform(UE4.FQuat(), targetOrigin)
  local detectActor = _G.UE4Helper.GetCurrentWorld():Abs_SpawnActor(UE4.ATriggerCapsule, spawnTransform, UE4.ESpawnActorCollisionHandlingMethod.AlwaysSpawn, nil, nil, nil, nil)
  local capsuleComp = detectActor.CollisionComponent
  if detectActor and capsuleComp then
    local function clearDetectActor()
      detectActor:K2_DestroyActor()
      
      detectActor = nil
    end
    
    capsuleComp:SetCapsuleSize(targetRadius, targetHalfHeight, false)
    local components = UE4.TArray(UE4.UPrimitiveComponent)
    local radius = math.max(extent.X, extent.Y)
    local halfHeight = extent.z
    if 0 == halfHeight then
      halfHeight = 10.0
      origin.Z = origin.Z + halfHeight
    end
    local bSuccess = UE4.UKismetSystemLibrary.CapsuleOverlapComponents(_G.UE4Helper.GetCurrentWorld(), origin, radius, halfHeight, {
      UE.EObjectTypeQuery.WorldDynamic
    }, {
      UE.UCapsuleComponent
    }, nil, components)
    if true == bSuccess then
      for _, component in tpairs(components) do
        if component == capsuleComp then
          if _G.NRCModuleManager:DoCmd(_G.MagicMessageModuleCmd.GetCanDrawDebug) then
            local displayName = npc:DebugNPCNameAndID()
            local duration = 0.03333333333333333
            UE4.UKismetSystemLibrary.DrawDebugCylinder(_G.UE4Helper.GetCurrentWorld(), origin - UE4.FVector(0, 0, halfHeight), origin + UE4.FVector(0, 0, halfHeight), radius, 20, UE4.FLinearColor(1, 0, 0, 1), duration, 2)
            UE4.UKismetSystemLibrary.Abs_DrawDebugString(_G.UE4Helper.GetCurrentWorld(), targetOrigin, displayName, nil, UE4.FLinearColor(1, 0.5, 0, 1), duration)
            UE4.UKismetSystemLibrary.Abs_DrawDebugCylinder(_G.UE4Helper.GetCurrentWorld(), targetOrigin - UE4.FVector(0, 0, targetHalfHeight), targetOrigin + UE4.FVector(0, 0, targetHalfHeight), targetRadius, 20, UE4.FLinearColor(1, 1, 0, 0.5), duration, 2)
          end
          clearDetectActor()
          return true
        end
      end
    end
    clearDetectActor()
  end
  return false
end

function MagicMessageUtils.DeleteLocalNpc(npc)
  if not npc then
    Log.Debug("MagicMessageUtils.DeleteLocalNpc: npc is nil")
    return
  end
  if npc.viewObj ~= false then
    Log.Debug("MagicMessageUtils.DeleteLocalNpc: npc.viewObj is not false")
    _G.NRCModuleManager:DoCmd(_G.NPCModuleCmd.DeleteLocalNPC, npc)
    return
  end
  
  local function onViewShellLoaded(caller, npc)
    Log.Debug("MagicMessageUtils.DeleteLocalNpc: \229\187\182\232\191\159\229\136\160\233\153\164")
    _G.NRCModuleManager:DoCmd(_G.NPCModuleCmd.DeleteLocalNPC, npc)
  end
  
  npc:AddEventListener(npc, NPCModuleEvent.VIEW_SHELL_LOADED, onViewShellLoaded)
end

function MagicMessageUtils.CreateLocalNPCWithActorInfo(ActorInfo)
  local npc = _G.NRCModuleManager:DoCmd(_G.NPCModuleCmd.CreateLocalNPCWithActorInfo, ActorInfo, PriorityEnum.Passive_World_Trace)
  return npc
end

function MagicMessageUtils.CreateLocalNPCBySelf(npcId, position, yaw)
  local npc = _G.NRCModuleManager:DoCmd(_G.NPCModuleCmd.CreateLocalNPC, npcId, position, yaw, nil, PriorityEnum.Active_Player_Throw_Npc)
  return npc
end

function MagicMessageUtils.GetSkillLoadPath(skill)
  local _, idx = skill:find(".*/")
  local package = skill:sub(1, idx)
  local asset = skill:sub(idx + 1, skill:len())
  local path = package .. asset .. "." .. asset .. "_C"
  return path
end

function MagicMessageUtils.PlayMessageSkill(npc, onLoadedCaller, onLoadedCallback)
  local skillPath = MagicMessageUtils.GetSkillLoadPath(npc.config.emerge_skill)
  
  local function onSkillPreEnd(name, skill)
    npc:SetVisible(true)
  end
  
  local function onLoadSuccess(caller, req, skillClass)
    local viewObj = npc.viewObj
    local ChildActor = viewObj.NRCChildActor:GetChildActor()
    local skillComp = viewObj and viewObj.RocoSkill
    if not skillComp then
      Log.Error("target npc has no skill component", npc.modelConf.id, npc.modelConf.path)
      return
    end
    if not skillClass then
      Log.Error("skill class is nil", skillPath)
      return
    end
    local skill = skillComp:FindOrAddSkillObj(skillClass)
    skill:SetCaster(ChildActor)
    skill:SetTargets({ChildActor})
    skill:RegisterEventCallback("End", npc, onSkillPreEnd)
    skillComp:StopCurrentSkill()
    
    local function onSkillLoaded(caller, skillObj)
      if onLoadedCallback then
        onLoadedCallback(onLoadedCaller)
      end
      skillComp:PlaySkill(skill)
    end
    
    skill.OnAsyncLoadCompleted:Add(viewObj, onSkillLoaded)
    skill:StartAsyncLoading()
  end
  
  local function onLoadFailed(caller, req, message)
    Log.Warning("SkillPath Load Failed", skillPath, message)
    if onLoadedCallback then
      onLoadedCallback(onLoadedCaller)
    end
    onSkillPreEnd()
  end
  
  _G.NRCResourceManager:LoadResAsync(self, skillPath, 1, 0, onLoadSuccess, onLoadFailed, nil)
end

function MagicMessageUtils.GetAvatarWandConfig(Type, IsFirst)
  local player = _G.NRCModuleManager:DoCmd(_G.PlayerModuleCmd.GET_LOCAL_PLAYER)
  if player then
    if Type == ProtoEnum.MarkGameplay.MK_MAGIC_MESSAGE then
      local wandData = player:GetCurWandDataByMagicType(ProtoEnum.SceneMagicType.SMT_CREATE_MAGIC_MASSAGE)
      if wandData then
        return wandData.MessageMagicResource
      end
    elseif Type == ProtoEnum.MarkGameplay.MK_MAGIC_VIDEO then
      if IsFirst then
        local wandData = player:GetCurWandDataByMagicType(ProtoEnum.SceneMagicType.SMT_CREATE_MAGIC_VIDEO)
        if wandData then
          return wandData.VideoMagicResource
        end
      else
        local param = _G.NRCModeManager:DoCmd(_G.MagicReplayModuleCmd.GetRecordFeedInitInfo)
        local conf = param.ChildConf
        local wand_id = 32500101
        if conf then
          wand_id = conf.wand_id
        end
        local WandConf = _G.DataConfigManager:GetFashionWandConf(wand_id, true)
        local avatarSystem = UE.USubsystemBlueprintLibrary.GetGameInstanceSubsystem(UE4Helper.GetCurrentWorld(), UE.UAvatarSubsystem)
        local type = ProtoEnum.SceneMagicType.SMT_CREATE_MAGIC_VIDEO
        local magic_id = WandConf.magic_list[type]
        if nil == magic_id or 0 == magic_id then
          magic_id = 1
        end
        local AvatarConfig = avatarSystem:GetAvatarConfig()
        local RowKey = AvatarConfig:GetWandDataRowKeyByMagic(magic_id, type)
        local returnRow = UE.FAvatarWandInfo_Video()
        UE.UDataTableFunctionLibrary.GetTableDataRowFromName(AvatarConfig.AvatarWandDataMap:Find(type), RowKey, returnRow)
        if returnRow then
          return returnRow.VideoMagicResource
        end
      end
    end
  end
end

function MagicMessageUtils.CreateParam(TraceType, npc, create_pos, valid)
  local param = {
    create_pos = create_pos.pos,
    npc_id = npc.serverData.base.actor_id,
    valid = valid,
    markType = TraceType,
    ChildConf = nil
  }
  local player = _G.NRCModuleManager:DoCmd(_G.PlayerModuleCmd.GET_LOCAL_PLAYER)
  local wandId = player:GetCurWandId()
  local config = _G.DataConfigManager:GetTable(DataConfigManager.ConfigTableId.MARK_MESSAGE_CHILD_CONF):GetAllDatas()
  for _, value in pairs(config) do
    if value.wand_id == wandId and value.gameplay_type == param.markType then
      param.ChildConf = value
      break
    end
  end
  return param
end

return MagicMessageUtils

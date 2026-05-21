local NPCModuleEvent = require("NewRoco.Modules.Core.NPC.NPCModuleEvent")
local ActorComponent = require("NewRoco.Modules.Core.Scene.Component.ActorComponent")
local BattleUtils = require("NewRoco.Modules.Core.Battle.Common.BattleUtils")
local PetMutationUtils = require("NewRoco.Utils.PetMutationUtils")
local RocoSkillProxy = require("NewRoco.Utils.RocoSkillProxy")
local SceneUtils = {}
SceneUtils.ClientNPCMask = 50331648
SceneUtils.ResLoadTest = {}
SceneUtils.ActorLoadTest = {}
SceneUtils.IsRuntime = true
SceneUtils.debugClosePlayerBlockTill = false
SceneUtils.debugBlockCreateAndLoad = false
SceneUtils.debugCloseCreateNPC = false
SceneUtils.debugCloseNPCLabel = false
SceneUtils.debugCloseCreateNPCView = false
SceneUtils.debugCloseNPCOnFrameLoad = false
SceneUtils.debugCloseNPCFacialAndWidget = false
SceneUtils.debugCloseNPCBasicResLoad = false
SceneUtils.debugCloseNPCABPLoad = false
SceneUtils.debugCloseNPCAnimConfigLoad = false
SceneUtils.debugCloseNPCModuleTick = false
SceneUtils.debugCloseCreateNPCComp = false
SceneUtils.debugCloseCreateAIComp = false
SceneUtils.debugCloseCreateInterComp = false
SceneUtils.debugCloseCreateLookComp = false
SceneUtils.debugCloseCreateHUDComp = false
SceneUtils.debugCloseCreateBornDieComp = false
SceneUtils.debugOpenCheckRes = false
SceneUtils.debugNPCSMResLoads = {}
SceneUtils.debugNPCSKMResLoads = {}
SceneUtils.debugNPCCascadeResLoads = {}
SceneUtils.debugNPCNiagaraResLoads = {}
SceneUtils.debugNPCACResLoads = {}
SceneUtils.debugNPCABPResLoads = {}
SceneUtils.debugNPCActorResLoads = {}
SceneUtils.debugCloseNPCPoolExtend = true
SceneUtils.debugCloseNPCPoolBurn = false
SceneUtils.debugCloseNPCPool = true
SceneUtils.debugDestroy = false
SceneUtils.debugCloseMinimap = false
SceneUtils.debugDisSqr = nil
SceneUtils.debugPoolExtendTime = nil
SceneUtils.debugPoolBurnTime = nil
SceneUtils.debugAlwaysBurn = false
SceneUtils.debugEnvLabel = false
SceneUtils.debugBattleBulkDataPreload = true
SceneUtils.debugOpenChangeCatchRate = false
SceneUtils.debugCatchRate = 0
SceneUtils.debugInterNavTargetPoint = false
SceneUtils.debugInterNavPathPoint = false
SceneUtils.debugInterNavPathForcePoint = true
SceneUtils.debugForceNpcOptionInvalid = false
SceneUtils.debugCoordFix = false
SceneUtils.debugGetPosInLandHit = false
SceneUtils.debugDisableAutoCollect = false
SceneUtils.BackWhiteList = {
  "BT_Rest",
  "BT_Patrol",
  "BT_Flee",
  "BT_HerdRest",
  "BT_Bird_S_GroundMove",
  "BT_Bird_S_RelaxOnRoof",
  "BT_Beetle_OnGround",
  "BT_Beetle_RestOnTree",
  "BT_Rest_Luoyin"
}
SceneUtils.TagRef1vN = {
  10,
  20,
  11,
  21,
  12,
  22
}
SceneUtils.TagRef1v1v1_cheer = {
  10,
  11,
  12
}
SceneUtils.TagRef1v1v1_against = {
  20,
  21,
  22
}
SceneUtils.EnableBattleExtraMemberFetching = true
SceneUtils.DelayReportPosNpcList = {}

function SceneUtils.GetPosInArea(areaId)
  local area = DataConfigManager:GetAreaConf(areaId)
  if #area.pos > 0 then
    local x = 0
    local y = 0
    local z = 0
    local len = #area.pos
    if len <= 3 then
      for i, v in ipairs(area.pos) do
        x = x + v.position_xyz[1]
        y = y + v.position_xyz[2]
        z = z + v.position_xyz[3]
      end
      x = x / len
      y = y / len
      z = z / len
    else
      local ran1 = math.random(1, len - 2)
      for i = ran1, ran1 + 2 do
        local pos = area.pos[i]
        x = x + pos.position_xyz[1]
        y = y + pos.position_xyz[2]
        z = z + pos.position_xyz[3]
      end
      x = x / 3
      y = y / 3
      z = z / 3
    end
    return UE4.FVector(x, y, z)
  end
end

function SceneUtils.GetPosInNav(pos, size, height, halfHeight)
  size = size or 100
  height = height or 400
  local QueryExtent = UE4.FVector(size, size, height)
  local ProjectedLocation, resValue = UE4.UNavigationSystemV1.Abs_K2_ProjectPointToNavigation(UE4Helper.GetCurrentWorld(), pos, nil, nil, nil, QueryExtent)
  if resValue then
    if halfHeight then
      ProjectedLocation.Z = ProjectedLocation.Z + halfHeight
    end
    return ProjectedLocation
  end
  return nil
end

function SceneUtils.GetPosInLine(pos, halfHeight, zUpOffset, zDownOffset, exclude, excludeAdd, isDown)
  if not pos then
    return nil
  end
  zUpOffset = zUpOffset or 1000
  zDownOffset = zDownOffset or 10000
  halfHeight = halfHeight or 0
  if nil == isDown then
    isDown = true
  end
  exclude = exclude or {}
  if excludeAdd then
    for _, v in pairs(excludeAdd) do
      table.insert(exclude, v)
    end
  end
  local lineBegin, lineEnd
  if isDown then
    lineBegin = UE4.FVector(pos.X, pos.Y, pos.Z + zUpOffset)
    lineEnd = UE4.FVector(pos.X, pos.Y, pos.Z - zDownOffset)
  else
    lineBegin = UE4.FVector(pos.X, pos.Y, pos.Z - zDownOffset)
    lineEnd = UE4.FVector(pos.X, pos.Y, pos.Z + zUpOffset)
  end
  local channel = {
    UE.EObjectTypeQuery.WaterSurface,
    UE.EObjectTypeQuery.WorldStatic
  }
  local hitResults, isHit = UE4.UKismetSystemLibrary.Abs_LineTraceMultiForObjects(UE4Helper.GetCurrentWorld(), lineBegin, lineEnd, channel, true, exclude)
  if isHit then
    for i = 1, hitResults:Length() do
      local hitResult = hitResults:Get(i)
      local hitActor = hitResult.Actor
      local name = UE.UKismetSystemLibrary.GetObjectName(hitActor)
      if not string.find(name, "BP_GrassRegionTrigger") and not string.find(name, "SM_EnvGraTree_Camphor") and not string.find(name, "BP_Sign") then
        local landPos = hitResult.ImpactPoint
        local SurfaceType = UE.UNRCStatics.GetSurfaceType(hitResult)
        if SurfaceType ~= UE.EPhysicalSurface.SurfaceType2 then
          landPos.Z = landPos.Z + halfHeight
        end
        local returnPos = UE4.FVector()
        returnPos.X = landPos.X
        returnPos.Y = landPos.Y
        returnPos.Z = landPos.Z
        if SceneUtils.debugCoordFix then
          Log.Debug("GetPosInLand \229\176\132\231\186\191\229\135\187\228\184\173", name)
        elseif SceneUtils.debugGetPosInLandHit then
          Log.Warning("GetPosInLand \229\176\132\231\186\191\229\135\187\228\184\173", name)
        end
        return returnPos
      end
    end
  end
  return nil
end

function SceneUtils.GetPosInLand(pos, halfHeight, zUpOffset, zDownOffset, exclude, excludeAdd, channel, isDown, bWaterAsLand, debug, defaultWorld)
  if not pos then
    return nil
  end
  zUpOffset = zUpOffset or 1000
  zDownOffset = zDownOffset or 10000
  halfHeight = halfHeight or 0
  if nil == debug then
    debug = false
  end
  if nil == isDown then
    isDown = true
  end
  bWaterAsLand = bWaterAsLand or false
  do
    local position = UE4.UNRCStatics.GetPosInLand(UE4Helper.GetCurrentWorld() or defaultWorld, pos, halfHeight, zUpOffset, zDownOffset, exclude, excludeAdd, isDown, bWaterAsLand)
    if UE.UKismetMathLibrary.Vector_IsNearlyZero(position) then
      return nil
    end
    return position
  end
  if not exclude then
    exclude = {}
    if SceneUtils.IsRuntime then
      local npcs = _G.NRCModeManager:DoCmd(_G.NPCModuleCmd.GetAllNPCInIter)
      if nil ~= npcs then
        for _, v in pairs(npcs) do
          table.insert(exclude, v.viewObj)
        end
      end
      local players = _G.NRCModeManager:DoCmd(_G.PlayerModuleCmd.GET_ALL_PLAYER)
      if nil ~= players then
        for _, v in pairs(players) do
          if v.viewObj then
            table.insert(exclude, v.viewObj)
          end
        end
      end
    end
  end
  if excludeAdd then
    for _, v in pairs(excludeAdd) do
      table.insert(exclude, v)
    end
  end
  local world = _G.UE4Helper.GetCurrentWorld()
  local lineBegin, lineEnd
  if isDown then
    lineBegin = UE4.FVector(pos.X, pos.Y, pos.Z + zUpOffset)
    lineEnd = UE4.FVector(pos.X, pos.Y, pos.Z - zDownOffset)
  else
    lineBegin = UE4.FVector(pos.X, pos.Y, pos.Z - zDownOffset)
    lineEnd = UE4.FVector(pos.X, pos.Y, pos.Z + zUpOffset)
  end
  if nil == channel then
    channel = {
      UE4.ECollisionChannel.ECC_WorldStatic
    }
    if bWaterAsLand then
      table.insert(channel, UE4.ECollisionChannel.ECC_GameTraceChannel13)
    end
  end
  local hitResults, isHit = UE4.UKismetSystemLibrary.Abs_LineTraceMultiForObjects(UE4Helper.GetCurrentWorld() or defaultWorld, lineBegin, lineEnd, channel, true, exclude)
  if isHit then
    if debug then
      for i = 1, hitResults:Length() do
        local hitResult = hitResults:Get(i)
        local hitActor = hitResult.Actor
        local name = UE.UKismetSystemLibrary.GetObjectName(hitActor)
        Log.Debug("GetPosInLand Hit Actor Log All", name)
      end
    end
    for i = 1, hitResults:Length() do
      local hitResult = hitResults:Get(i)
      local hitActor = hitResult.Actor
      local name = UE.UKismetSystemLibrary.GetObjectName(hitActor)
      if debug then
        Log.Debug("GetPosInLand Hit Actor", name)
      end
      if (bWaterAsLand or not string.find(name, "Water", 1)) and not string.find(name, "BP_NPC") and not string.find(name, "BP_GrassRegionTrigger") and not string.find(name, "SM_EnvGraTree_Camphor") and not string.find(name, "BP_Sign") then
        local landPos = hitResult.ImpactPoint
        landPos.Z = landPos.Z + halfHeight
        local pos = UE4.FVector()
        pos.X = landPos.X
        pos.Y = landPos.Y
        pos.Z = landPos.Z
        if SceneUtils.debugCoordFix then
          Log.Debug("GetPosInLand \229\176\132\231\186\191\229\135\187\228\184\173 \230\156\128\231\187\136\229\136\164\229\174\154", name)
        elseif SceneUtils.debugGetPosInLandHit then
          Log.Warning("GetPosInLand \229\176\132\231\186\191\229\135\187\228\184\173 \230\156\128\231\187\136\229\136\164\229\174\154", name)
        end
        return pos
      end
    end
  end
  return nil
end

function SceneUtils.GetPosInNearLand(pos, halfHeight, exclude, excludeAdd, bWaterAsLand)
  if not pos then
    return
  end
  local downPos = SceneUtils.GetPosInLand(pos, halfHeight, 5, 10000, exclude, excludeAdd, nil, true, bWaterAsLand)
  local upPos = SceneUtils.GetPosInLand(pos, halfHeight, 10000, 5, exclude, excludeAdd, nil, false, bWaterAsLand)
  if not downPos and not upPos then
    return nil
  end
  if not downPos then
    return upPos
  end
  if not upPos then
    return downPos
  end
  local downOffset = math.abs(downPos.Z - pos.Z)
  local upOffset = math.abs(upPos.Z - pos.Z)
  if downOffset < upOffset then
    return downPos
  else
    return upPos
  end
end

function SceneUtils.GetPosInLand_ByVisible(pos, halfHeight, zUpOffset, zDownOffset, exclude, channel, bWaterAsLand, debug)
  zUpOffset = zUpOffset or 10000
  zDownOffset = zDownOffset or 20000
  return SceneUtils.GetPosInLand(pos, halfHeight, zUpOffset, zDownOffset, exclude, nil, channel, true, bWaterAsLand, debug)
end

function SceneUtils.IsLogicStatusUnlock(npc)
  if not npc then
    return true
  end
  return not npc:IsLogicStatus(ProtoEnum.SpaceActorLogicStatus.SALS_LOCKED)
end

function SceneUtils.IsServerStatusUnlock(npc)
  if not npc then
    return nil
  end
  local lock = npc:IsServerStatus(ProtoEnum.SpaceActorLogicStatus.SALS_LOCKED)
  if nil == lock then
    return nil
  else
    return not lock
  end
end

function SceneUtils.IsLogicStatusLightBallUnlock(npc)
  if not npc then
    return false
  end
  return not npc:IsLogicStatus(ProtoEnum.SpaceActorLogicStatus.SALS_LIGHTBALL_LOCKED)
end

function SceneUtils.IsLogicStatusUnlockJiDian(npc)
  if not npc then
    return false
  end
  return not npc:IsLogicStatus(ProtoEnum.SpaceActorLogicStatus.SALS_LOCKED_BY_JIDIAN)
end

function SceneUtils.IsLogicStatusGrownup(npc)
  if not npc then
    return false
  end
  return npc:IsLogicStatus(ProtoEnum.SpaceActorLogicStatus.SALS_GROUWUP)
end

function SceneUtils.IsLogicStatusTriggerOff(npc)
  if not npc then
    return false
  end
  return npc:IsLogicStatus(ProtoEnum.SpaceActorLogicStatus.SALS_TRIGGER_OFF)
end

function SceneUtils.IsLogicStatusTriggerOn(npc)
  if not npc then
    return false
  end
  local IsOff = npc:IsLogicStatus(ProtoEnum.SpaceActorLogicStatus.SALS_TRIGGER_OFF)
  if IsOff then
    return false
  end
  local IsOn = npc:IsLogicStatus(ProtoEnum.SpaceActorLogicStatus.SALS_TRIGGER_ON)
  return IsOn
end

function SceneUtils.IsLogicStatusPlantUnlockLand(npc)
  if not npc then
    return false
  end
  return npc:IsLogicStatus(ProtoEnum.SpaceActorLogicStatus.SALS_HOME_PLANT_UNLOCK_LAND)
end

function SceneUtils.IsLogicStatusHomePlantUnlockEntry(npc)
  if not npc then
    return false
  end
  return npc:IsLogicStatus(ProtoEnum.SpaceActorLogicStatus.SALS_HOME_PLANT_UNLOCK_ENTRY_NPC)
end

function SceneUtils.IsLogicStatusInteracting(npc)
  if not npc then
    return false
  end
  return npc:IsLogicStatus(ProtoEnum.SpaceActorLogicStatus.SALS_INTERACTING)
end

function SceneUtils.IsLogicStatusBonfireActivated(npc)
  if not npc then
    return false
  end
  return npc:IsLogicStatus(ProtoEnum.SpaceActorLogicStatus.SALS_BONFIRE_ACTIVE)
end

function SceneUtils.IsLogicStatusGrowUpActivated(npc)
  if not npc then
    return false
  end
  return npc:IsLogicStatus(ProtoEnum.SpaceActorLogicStatus.SALS_GROUWUP)
end

function SceneUtils.IsLogicStatusCharmActivated(npc)
  if not npc then
    return false
  end
  return npc:IsLogicStatus(ProtoEnum.SpaceActorLogicStatus.SALS_NAUTYCHEST_CHARM)
end

function SceneUtils.IsLogicStatusHipnosisActivated(npc)
  if not npc then
    return false
  end
  return npc:IsLogicStatus(ProtoEnum.SpaceActorLogicStatus.SALS_NAUTYCHEST_HIPNOSIS)
end

function SceneUtils.IsLogicStatusFearActivated(npc)
  if not npc then
    return false
  end
  return npc:IsLogicStatus(ProtoEnum.SpaceActorLogicStatus.SALS_NAUTYCHEST_FEAR)
end

function SceneUtils.IsLogicStatusBlindActivated(npc)
  if not npc then
    return false
  end
  return npc:IsLogicStatus(ProtoEnum.SpaceActorLogicStatus.SALS_NAUTYCHEST_BLIND)
end

function SceneUtils.IsLogicStatusNightmareBossActivated(npc)
  if not npc then
    return false
  end
  return npc:IsLogicStatus(ProtoEnum.SpaceActorLogicStatus.SALS_NIGHTMARE_BOSS)
end

function SceneUtils.IsLogicStatusNightmareEliteActivated(npc)
  if not npc then
    return false
  end
  return npc:IsLogicStatus(ProtoEnum.SpaceActorLogicStatus.SALS_NIGHTMARE_ELITE)
end

function SceneUtils.IsLogicStatusGhostActivated(npc)
  if not npc then
    return false
  end
  return npc:IsLogicStatus(ProtoEnum.SpaceActorLogicStatus.SALS_GHOST_ACTIVE)
end

function SceneUtils.IsLogicStatusStarGlow1(npc)
  if not npc then
    return false
  end
  local state = npc:IsLogicStatus(ProtoEnum.SpaceActorLogicStatus.SALS_STARGLOW_LIGHT_1)
  return state
end

function SceneUtils.IsLogicStatusStarGlow2(npc)
  if not npc then
    return false
  end
  local state = npc:IsLogicStatus(ProtoEnum.SpaceActorLogicStatus.SALS_STARGLOW_LIGHT_2)
  return state
end

function SceneUtils.DebugOnlyNear(npc, callback, ratio)
  if not npc or not callback then
    return
  end
  ratio = ratio or 0.5
  if ratio > npc.distanceRatio then
    callback()
  end
end

function SceneUtils.CorrectActorPos(actor, bChangeNeedAdjust)
  if actor.SendPosToServer then
    actor:SendPosToServer()
  end
  if bChangeNeedAdjust and actor.sceneCharacter then
    actor.sceneCharacter:ChangeNeedPosAdjust(false, true)
  end
end

function SceneUtils.EnsureNPCsPos(npcInfos, type)
  type = type or 0
  Log.Debug("SceneUtils.CorrectActorPosByNpcInfo")
  local req = _G.ProtoMessage:newZoneSceneSetNpcPosReq()
  for _, npcInfo in pairs(npcInfos) do
    local item = _G.ProtoMessage:newSetNpcPosItem()
    item.npc_id = npcInfo.base.actor_id
    item.npc_logic_id = npcInfo.base.logic_id
    item.pt = npcInfo.base.pt
    item.op_type = type
    table.insert(req.npc_list, item)
  end
  _G.ZoneServer:Send(_G.ProtoCMD.ZoneSvrCmd.ZONE_SCENE_SET_NPC_POS_REQ, req)
end

function SceneUtils.DelayReportNpcPosition(Npc, NpcList, Reset)
  Reset = false
  if not Npc and not NpcList then
    return
  end
  if Npc then
    table.insert(SceneUtils.DelayReportPosNpcList, Npc)
  end
  if NpcList then
    for _, item in pairs(NpcList) do
      table.insert(SceneUtils.DelayReportPosNpcList, item)
    end
  end
  if Reset then
    if not SceneUtils.ResetNpcPosSet then
      SceneUtils.ResetNpcPosSet = {}
    end
    SceneUtils.ResetNpcPosSet[Npc.npc_id] = true
    SceneUtils.ShouldResetNpcPos = true
  end
  if SceneUtils.DelayReportPositionTimer == nil then
    SceneUtils.DelayReportPositionTimer = _G.DelayManager:DelaySeconds(0.3, SceneUtils.ReportNpcPosition)
  end
end

local SyncNpcSet = {}

function SceneUtils.ReportNpcPosition()
  local Req = _G.ProtoMessage:newZoneSceneSetNpcPosReq()
  table.clear(SyncNpcSet)
  if SceneUtils.DelayReportPosNpcList and #SceneUtils.DelayReportPosNpcList > 0 then
    for i = #SceneUtils.DelayReportPosNpcList, 1, -1 do
      local ReportNpcPos = SceneUtils.DelayReportPosNpcList[i]
      if not ReportNpcPos then
      elseif not table.containsKey(SyncNpcSet, ReportNpcPos.npc_id) then
        SyncNpcSet[ReportNpcPos.npc_id] = true
        table.insert(Req.npc_list, ReportNpcPos)
      end
    end
  end
  table.reverse(Req.npc_list)
  if SceneUtils.ShouldResetNpcPos then
    _G.ZoneServer:SendWithHandler(_G.ProtoCMD.ZoneSvrCmd.ZONE_SCENE_SET_NPC_POS_REQ, Req, SceneUtils, SceneUtils.OnReportPositionRsp, false, true)
  else
    _G.ZoneServer:Send(_G.ProtoCMD.ZoneSvrCmd.ZONE_SCENE_SET_NPC_POS_REQ, Req)
  end
  for _, NpcItem in ipairs(SceneUtils.DelayReportPosNpcList) do
    local NPC = _G.NRCModuleManager:DoCmd(_G.NPCModuleCmd.GetNpcByServerID, NpcItem.npc_id)
    if NPC then
      NPC:ChangeNeedPosAdjust(false, false)
    end
  end
  SceneUtils.DelayReportPosNpcList = {}
  if SceneUtils.DelayReportPositionTimer then
    _G.DelayManager:CancelDelayById(SceneUtils.DelayReportPositionTimer)
    SceneUtils.DelayReportPositionTimer = nil
  end
end

function SceneUtils.OnReportPositionRsp(Rsp)
  if not SceneUtils.ShouldResetNpcPos then
    return
  end
  if Rsp.failed_npc_list and #Rsp.failed_npc_list > 0 then
    for _, NpcItem in ipairs(Rsp.failed_npc_list) do
      if SceneUtils.ResetNpcPosSet and SceneUtils.ResetNpcPosSet[NpcItem.npc_id] then
        local NPC = _G.NRCModuleManager:DoCmd(_G.NPCModuleCmd.GetNpcByServerID, NpcItem.npc_id)
        if NPC and not NPC.isDestroy and NPC.viewObj then
          local HalfHeight = NPC:GetScaledHalfHeight()
          if HalfHeight ~= HalfHeight then
            HalfHeight = 0
          end
          NpcItem.pt.pos.z = NpcItem.pt.pos.z + HalfHeight
          NPC.viewObj:Abs_K2_SetActorLocationAndRotation_WithoutHit(SceneUtils.ServerPos2ClientPos(NpcItem.pt.pos), SceneUtils.ServerPos2ClientRotator(NpcItem.pt.dir))
        end
      end
    end
  end
  SceneUtils.ShouldResetNpcPos = false
  table.clear(SceneUtils.ResetNpcPosSet)
end

function SceneUtils.GetActorMesh(actor)
  local meshComponent
  if actor and UE4.UObject.IsValid(actor) then
    meshComponent = actor:GetComponentByClass(UE4.USkeletalMeshComponent)
    if not meshComponent or not meshComponent.SkeletalMesh then
      meshComponent = actor:GetComponentByClass(UE4.UStaticMeshComponent)
    end
  end
  return meshComponent
end

function SceneUtils.ClientPos2ServerPos(pos, factor, InPos)
  if not pos then
    Log.Error("SceneUtil ClientPos2ServerPos param pos is nil")
    return nil
  end
  factor = factor or 1.0
  pos = pos * factor
  local serverPos
  if InPos then
    serverPos = InPos
  else
    serverPos = ProtoMessage:newPosition()
  end
  serverPos.x = math.round(pos.X)
  serverPos.y = math.round(pos.Y)
  serverPos.z = math.round(pos.Z)
  return serverPos
end

function SceneUtils.ServerPos2ClientPos(pos, factor)
  if not pos then
    return UE.FVector(0, 0, 0)
  end
  if factor and 1.0 ~= factor then
    return UE4.FVector((pos.x or 0) / factor, (pos.y or 0) / factor, (pos.z or 0) / factor)
  else
    return UE4.FVector(pos.x or 0, pos.y or 0, pos.z or 0)
  end
end

function SceneUtils.ServerPos2ClientPosInPlace(pos, factor, InVec)
  InVec = InVec or UE.FVector()
  if not pos then
    return InVec:Set(0, 0, 0)
  end
  if factor and 1.0 ~= factor then
    InVec:Set((pos.x or 0) / factor, (pos.y or 0) / factor, (pos.z or 0) / factor)
  else
    InVec:Set(pos.x or 0, pos.y or 0, pos.z or 0)
  end
  return InVec
end

function SceneUtils.DebugPositionToString(pos)
  local LogLevel = Log.GetLogLevel()
  if LogLevel > Log.LOG_LEVEL.ELogDebug then
    return
  end
  if not pos then
    return "X: 0, Y: 0, Z: 0"
  end
  return string.format("X: %f, Y: %f, Z: %f", pos.x or 0, pos.y or 0, pos.z or 0)
end

function SceneUtils.DebugVectorToString(vector)
  local LogLevel = Log.GetLogLevel()
  if LogLevel > Log.LOG_LEVEL.ELogDebug then
    return
  end
  if not vector then
    return "X: 0, Y: 0, Z: 0"
  end
  return string.format("X: %f, Y: %f, Z: %f", vector.X, vector.Y, vector.Z)
end

function SceneUtils.ConvertVectorToPoint(vector, point)
  if nil == point then
    point = ProtoMessage:newPoint()
  end
  local lMath = math.round
  point.pos.x = lMath(vector.X)
  point.pos.y = lMath(vector.Y)
  point.pos.z = lMath(vector.Z)
  return point
end

function SceneUtils.ConvertPointToVector(point, vector)
  if nil == vector then
    vector = UE4.FVector()
  end
  vector.X = point.pos.x
  vector.Y = point.pos.y
  vector.Z = point.pos.z
  return vector
end

function SceneUtils.ConvertTransformToPoint(transform, point)
  if nil == point then
    point = ProtoMessage:newPoint()
  end
  SceneUtils.ConvertVectorToPoint(transform.Translation, point)
  local rot = transform.Rotation:ToRotator()
  point.dir.z = math.round((rot.Yaw or 0) * 10)
  point.dir.x = math.round((rot.Roll or 0) * 10)
  point.dir.y = math.round((rot.Pitch or 0) * 10)
  return point
end

function SceneUtils.ConvertPointToTransform(point, transform)
  if nil == transform then
    transform = UE4.FTransform()
  end
  SceneUtils.Pos2Vec(point.pos, transform.Translation)
  local quat = SceneUtils.Point2Rot(point)
  transform.Rotation = quat:ToQuat()
  return transform
end

function SceneUtils.ClientRotator2ServerPos(rotator, factor, InPos)
  if not rotator then
    Log.Error("SceneUtil ServerPos2ClientPos param rotator is nil")
  end
  local serverPos
  if InPos then
    serverPos = InPos
  else
    serverPos = ProtoMessage:newPosition()
  end
  factor = factor or 10.0
  rotator = rotator * factor
  serverPos.x = math.round(rotator.Roll)
  serverPos.y = math.round(rotator.Pitch)
  serverPos.z = math.round(rotator.Yaw)
  return serverPos
end

function SceneUtils.ServerPos2ClientRotator(pos, factor)
  if not pos then
    return _G.FRotatorZero
  end
  factor = factor or 10.0
  local x = (pos.x or 0) / factor
  local y = (pos.y or 0) / factor
  local z = (pos.z or 0) / factor
  return UE4.FRotator(y, z, x)
end

function SceneUtils.ServerDir2ClientRotator(dir)
  dir = math.rad(dir / 10.0)
  return UE4.FVector(math.cos(dir), math.sin(dir), 0):ToRotator()
end

local DetailTypeAvatar = ProtoEnum.SpaceEnum_ActorDetailType.ENUM.Avatar_Normal

function SceneUtils.FixActorPoint(Info)
  if not Info then
    return
  end
  local BaseInfo
  if Info.actor_detail_type == DetailTypeAvatar then
    BaseInfo = Info.avatar.base
  else
    BaseInfo = Info.npc.base
  end
  SceneUtils.FillPoint(BaseInfo.born_pt)
  SceneUtils.FillPoint(BaseInfo.pt)
end

local NewPosition = _G.ProtoMessage.newPosition

local function FillPosition(Position)
  if Position then
    Position.x = Position.x or 0
    Position.y = Position.y or 0
    Position.z = Position.z or 0
  else
    Position = NewPosition()
    Position.x = 0
    Position.y = 0
    Position.z = 0
  end
  return Position
end

function SceneUtils.FillPoint(Point)
  if not Point then
    return
  end
  Point.pos = FillPosition(Point.pos)
  Point.dir = FillPosition(Point.dir)
end

function SceneUtils.GetPlayer(ServerID)
  if ServerID then
    local Player = _G.NRCModuleManager:DoCmd(_G.PlayerModuleCmd.GetPlayerByServerID, ServerID)
    return Player
  end
  local Player = _G.NRCModeManager:DoCmd(_G.PlayerModuleCmd.GET_LOCAL_PLAYER)
  return Player
end

function SceneUtils.GetActorByServerId(ServerID)
  if ServerID then
    local Player = _G.NRCModuleManager:DoCmd(_G.PlayerModuleCmd.GetPlayerByServerID, ServerID)
    if Player then
      return Player, true
    end
    local Npc = _G.NRCModuleManager:DoCmd(_G.NPCModuleCmd.GetNpcByServerID, ServerID)
    if Npc then
      return Npc, false
    end
  end
  return nil, false
end

function SceneUtils.FindNPC(id)
  local npc = _G.NRCModeManager:DoCmd(_G.NPCModuleCmd.FindNPCByConfigId, id)
  return npc
end

function SceneUtils.GetPlayerView(Player)
  return Player and Player.viewObj
end

function SceneUtils.GetDirection(a, b, ignoreZ)
  if not a or not b then
    return nil
  end
  local aPos = a:GetActorLocation()
  local bPos = b:GetActorLocation()
  local dir = bPos - aPos
  if ignoreZ then
    dir.Z = 0
  end
  return dir:ToRotator():Clamp()
end

function SceneUtils.LookAt(a, b)
  if not a or not b then
    return
  end
  local Rot = SceneUtils.GetDirection(a, b, true)
  if Rot then
    a:SetActorRotation(Rot)
  end
end

function SceneUtils.GetPetBaseConf(NPC)
  local DataConfigManager = _G.DataConfigManager
  local PetBaseID = 0
  local NPCBase = NPC.serverData.npc_base
  local NPCConfigID = NPCBase.npc_cfg_id
  local monsterConfID = 0
  local NPCConf = DataConfigManager:GetNpcConf(NPCConfigID)
  if not NPCConf then
    Log.Error("SceneUtils.GetPetBaseConf Error: npc conf does not exist", NPCConfigID)
    return nil, nil
  end
  local FirstOption = NPCConf.option_id and NPCConf.option_id[1]
  if not FirstOption then
    Log.Error("SceneUtils.GetPetBaseConf Error: can't get first option of npc", NPCConfigID)
    return nil, nil
  end
  local OptionConf = DataConfigManager:GetNpcOptionConf(FirstOption)
  if not OptionConf or not OptionConf.action then
    Log.Error("SceneUtils.GetPetBaseConf Error: option conf error", NPCConfigID)
    return nil, nil
  end
  if OptionConf.action.action_type ~= Enum.ActionType.ACT_BATTLE and OptionConf.action.action_type ~= Enum.ActionType.ACT_TOUCHBATTLE then
    Log.Error("SceneUtils.GetPetBaseConf Error: action not a battle", FirstOption)
    return nil, nil
  end
  if string.IsNilOrEmpty(OptionConf.action.action_param2) then
    Log.Error("SceneUtils.GetPetBaseConf Error: action param is nil", FirstOption)
    return nil, nil
  end
  local BattleID = tonumber(OptionConf.action.action_param2)
  local BattleConf = DataConfigManager:GetBattleConf(BattleID)
  if not BattleConf then
    Log.Error("SceneUtils.GetPetBaseConf Error: can't find valid battle ID", BattleID)
    return nil, nil
  end
  local NPCList = BattleConf.npc_battle_list and BattleConf.npc_battle_list[1]
  if not NPCList then
    Log.Error("SceneUtils.GetPetBaseConf Error: can't find valid battle ID", BattleID)
    return nil, nil
  end
  monsterConfID = NPCList.pos1_1st and NPCList.pos1_1st[1] or 0
  if 0 == monsterConfID then
    Log.Error("SceneUtils.GetPetBaseConf Error: can't find valid monster id", BattleID)
    return nil, nil
  end
  local MonsterConf = DataConfigManager:GetMonsterConf(monsterConfID)
  if not MonsterConf then
    Log.Error("SceneUtils.GetPetBaseConf Error: Can't find monster conf id", monsterConfID)
    return nil, nil
  end
  PetBaseID = MonsterConf and MonsterConf.base_id or 0
  Log.Debug("SceneUtils.GetPetBaseConf", NPCConfigID, monsterConfID, PetBaseID)
  local PetBaseConf = DataConfigManager:GetPetbaseConf(PetBaseID)
  return PetBaseConf, MonsterConf
end

function SceneUtils.GetCatchRate(Session, NPC)
  local catchTimes = 0
  local PetBaseID = 0
  local npcAIState = 0
  local dist = 0
  local BallID = Session.itemData.id
  local ActorBase = NPC.serverData.base
  local NPCLevel = ActorBase.lv
  local PetBaseConf, MonsterConf = SceneUtils.GetPetBaseConf(NPC)
  if not PetBaseConf then
    Log.Error("SceneUtils.GetCatchRate can't find PETBASE_CONF", NPC:DebugNPCNameAndID())
    return 0, 0
  end
  PetBaseID = PetBaseConf.id
  local guaranteeRate = 0
  local lastCatchTime = 0
  if NPC.serverData.npc_base then
    guaranteeRate = NPC.serverData.npc_base.catch_guarantee_rate or 0
    lastCatchTime = NPC.serverData.npc_base.last_catch_time or 0
  end
  local CatchInfo = _G.DataModelMgr.PlayerDataModel:GetPetCatchInfo(PetBaseConf.id)
  if CatchInfo then
    catchTimes = CatchInfo.success_count or 0
  else
    catchTimes = 0
  end
  local player = NRCModeManager:DoCmd(PlayerModuleCmd.GET_LOCAL_PLAYER)
  local playerLocation = player.viewObj:Abs_K2_GetActorLocation()
  local targetNPCLocation = NPC:GetActorLocation()
  dist = ((targetNPCLocation.X - playerLocation.X) ^ 2 + (targetNPCLocation.Y - playerLocation.Y) ^ 2) ^ 0.5
  local forwardVec = targetNPCLocation - playerLocation
  local bTriggerBackwardBattle = SceneUtils.TriggerBackwardCatch(NPC, forwardVec)
  if NPC.AIComponent then
    if not bTriggerBackwardBattle then
      npcAIState = npcAIState + _G.ProtoEnum.ThrowTargetNpcAIStatus.DETECTED_AVATAR
    end
    if NPC.AIComponent:IsResistCapture() or NPC.HiddenComponent and NPC.HiddenComponent:IsResistCapture(BallID) then
      npcAIState = npcAIState + _G.ProtoEnum.ThrowTargetNpcAIStatus.RESIST_CATCH
    end
  end
  local Dizzy = false
  if NPC.AIComponent then
    local sneakBuffConf = _G.DataConfigManager:GetGlobalConfig("sneak_correction_bigworld")
    if sneakBuffConf and sneakBuffConf.str then
      local sneakBuffStrList = string.Split(sneakBuffConf.str, ";")
      for _, param in ipairs(sneakBuffStrList) do
        if NPC.AIComponent:HasBattleState(Enum.BattleAIStatus[param]) then
          Dizzy = true
          break
        end
      end
    end
  end
  local bMatchBallState = false
  local hasTrue = false
  if NPC.AIComponent then
    local BallConf = BallID and 0 ~= BallID and _G.DataConfigManager:GetBallConf(BallID)
    local tableConfState = BallConf and BallConf.param_blackboard
    if tableConfState and #tableConfState > 0 then
      for _, param in ipairs(tableConfState) do
        if NPC.AIComponent.AIController:QueryCrossBlackboardValue(param, LuaParamType.Bool) == true then
          hasTrue = true
        end
        if hasTrue then
          break
        end
      end
    end
    if hasTrue then
      bMatchBallState = true
    end
  end
  local Rate = BattleUtils.CalculateCatchMonsterRate(BallID, MonsterConf.id, NPCLevel, catchTimes, npcAIState, dist, Dizzy, bMatchBallState, guaranteeRate, lastCatchTime) or 0
  if 0 ~= npcAIState & _G.ProtoEnum.ThrowTargetNpcAIStatus.RESIST_CATCH then
    Rate = 0
  end
  if true == SceneUtils.debugOpenChangeCatchRate then
    Rate = SceneUtils.debugCatchRate
  end
  if GlobalConfig.ShowCatchRate then
    Log.Error("SceneUtils.GetCatchRate", BallID, NPC:DebugNPCNameAndID(), Rate, MonsterConf.id, NPCLevel, catchTimes)
  end
  return Rate, PetBaseID
end

function SceneUtils.GetActorType(id)
  if 0 == id then
    return 0
  end
  return (id & -1152921504606846976) >> 60 & 15
end

function SceneUtils.GetActorDetailType(id)
  local recognizeBits1 = (id & 50331648) >> 24
  if 1 == recognizeBits1 then
    return ProtoEnum.SpaceEnum_ActorDetailType.ENUM.Npc_Scene
  elseif 2 == recognizeBits1 then
    return ProtoEnum.SpaceEnum_ActorDetailType.ENUM.Npc_DropItem
  end
  local recognizeBits2 = (id & 15728640) >> 20
  return recognizeBits2
end

function SceneUtils.GetSceneID()
  local SceneModule = _G.NRCModuleManager:GetModule("SceneModule")
  if SceneModule then
    return SceneModule:GetCurrentMapId()
  else
    return nil
  end
end

function SceneUtils.GetSceneResId()
  local SceneModule = _G.NRCModuleManager:GetModule("SceneModule")
  if SceneModule then
    return SceneModule:GetCurrentMapResId()
  else
    return nil
  end
end

function SceneUtils.GetSceneResConf()
  local ID = SceneUtils.GetSceneResId()
  if not ID or 0 == ID then
    return nil
  end
  local Conf = _G.DataConfigManager:GetSceneResConf(ID)
  return Conf
end

function SceneUtils.ConvertRelativeToAbsolute(location)
  local World = _G.UE4Helper.GetCurrentWorld()
  local OffsetX = World:GetWorldOriginX()
  local OffsetY = World:GetWorldOriginY()
  local OffsetZ = World:GetWorldOriginZ()
  return UE.FVector(location.X + OffsetX, location.Y + OffsetY, location.Z + OffsetZ)
end

function SceneUtils.ConvertAbsoluteToRelative(location)
  local World = _G.UE4Helper.GetCurrentWorld()
  local OffsetX = World:GetWorldOriginX()
  local OffsetY = World:GetWorldOriginY()
  local OffsetZ = World:GetWorldOriginZ()
  return UE.FVector(location.X - OffsetX, location.Y - OffsetY, location.Z - OffsetZ)
end

function SceneUtils.ConvertAbsoluteToRelativeInPlace(Abs, Rel)
  local World = _G.UE4Helper.GetCurrentWorld()
  local OffsetX = World:GetWorldOriginX()
  local OffsetY = World:GetWorldOriginY()
  local OffsetZ = World:GetWorldOriginZ()
  Rel.X = Abs.X - OffsetX
  Rel.Y = Abs.Y - OffsetY
  Rel.Z = Abs.Z - OffsetZ
end

function SceneUtils.Pos2Vec(Pos, Vec)
  if Vec then
    Vec.X = Pos.x
    Vec.Y = Pos.y
    Vec.Z = Pos.z
  else
    Vec = UE.FVector(Pos.x, Pos.y, Pos.z)
  end
  return Vec
end

function SceneUtils.Point2Rot(point, rot)
  local pitch = (point.dir.y or 0) / 10
  local yaw = (point.dir.z or 0) / 10
  local roll = (point.dir.x or 0) / 10
  if rot then
    rot.Pitch = pitch
    rot.Yaw = yaw
    rot.Roll = roll
  else
    rot = UE.FRotator(pitch, yaw, roll)
  end
  return rot
end

function SceneUtils.SplitPoint(Point)
  local Pos = SceneUtils.Pos2Vec(Point.pos)
  local Rot = UE.FRotator((Point.dir.y or 0) / 10, (Point.dir.z or 0) / 10, (Point.dir.x or 0) / 10)
  return Pos, Rot
end

function SceneUtils.MergePoint(Pos, Rot)
  local Point = _G.ProtoMessage:newPoint()
  if Pos then
    Point.pos.x = math.round(Pos.X)
    Point.pos.y = math.round(Pos.Y)
    Point.pos.z = math.round(Pos.Z)
  end
  if Rot then
    Point.dir.z = math.round((Rot.Yaw or 0) * 10)
    Point.dir.x = math.round((Rot.Roll or 0) * 10)
    Point.dir.y = math.round((Rot.Pitch or 0) * 10)
  end
  return Point
end

function SceneUtils.GetEnvLabelsByPos(Pos)
  local labels, num = UE.UDotsLabelStatics.GetAllLabelTypeByPos(Pos)
  if num > 0 then
    local tags = {}
    for _, label in tpairs(labels) do
      table.insert(tags, label.Tag)
    end
    if SceneUtils.debugEnvLabel then
      local DebugString = "tag:"
      for _, label in ipairs(tags) do
        DebugString = DebugString .. tostring(label) .. " "
      end
      UE4.UKismetSystemLibrary.Abs_DrawDebugString(UE4Helper.GetCurrentWorld(), Pos, DebugString, nil, UE4.FLinearColor(0, 0, 1, 1), 10)
    end
    return tags
  end
  return nil
end

function SceneUtils.GetDefaultMonsterId(npc)
  if not npc then
    return nil, -1
  end
  local option = npc.InteractionComponent:GetMainAction()
  if not option then
    return nil, -2
  end
  local isBattleType = option.config.pet_action.action_type == Enum.ActionType.ACT_BATTLE
  isBattleType = isBattleType or option.config.pet_action.action_type == Enum.ActionType.ACT_TOUCHBATTLE
  if not isBattleType then
    return nil, -3
  end
  local battleId = tonumber(option.config.pet_action.action_param2)
  local battleConf = DataConfigManager:GetBattleConf(battleId, true)
  if not battleConf then
    return nil, -4
  end
  local battle_list = battleConf.npc_battle_list[1]
  if not battle_list then
    return nil, -5
  end
  return battle_list.pos1_1st[1], 0
end

function SceneUtils.RegisterNPCVisibilityNotify(Comp, CallIfAlreadyVisible)
  if not Comp then
    return
  end
  local Owner = Comp.owner
  if not Owner then
    return
  end
  if Comp.OnVisible ~= ActorComponent.OnVisible then
    Owner:AddEventListener(Comp, NPCModuleEvent.OnViewVisible, Comp.OnVisible)
    if CallIfAlreadyVisible and Owner.viewObj and Owner.viewObj.resourceLoaded then
      Comp:OnVisible()
    end
  else
    Log.Error("\232\175\183\233\135\141\232\189\189OnVisible", Comp.name)
  end
  if Comp.OnInvisible ~= ActorComponent.OnInvisible then
    Owner:AddEventListener(Comp, NPCModuleEvent.OnViewInvisible, Comp.OnInvisible)
  else
    Log.Error("\232\175\183\233\135\141\232\189\189OnInvisible", Comp.name)
  end
end

function SceneUtils.UnregisterNPCVisibilityNotify(Comp)
  if not Comp then
    return
  end
  local Owner = Comp.owner
  if not Owner then
    return
  end
  if Comp.OnVisible ~= ActorComponent.OnVisible then
    Owner:RemoveEventListener(Comp, NPCModuleEvent.OnViewVisible, Comp.OnVisible)
  end
  if Comp.OnInvisible ~= ActorComponent.OnInvisible then
    Owner:RemoveEventListener(Comp, NPCModuleEvent.OnViewInvisible, Comp.OnInvisible)
  end
end

SceneUtils.BackwardBattleConditionResult = {
  AlwaysCant = 0,
  AlwaysCan = 1,
  ByAngle = 2,
  ByAngleAndControlFlag = 3
}

function SceneUtils.GetBackwardBattleCondition(sceneNpc, type, ScenePet)
  if 1 == type and ScenePet then
    local bContains, param = ScenePet:ContainsRealSpecialityEffect(Enum.PetTalentEffect.PTE_BACKSTAB, true)
    if bContains then
      if 1 == param then
        return SceneUtils.BackwardBattleConditionResult.AlwaysCan
      elseif 0 == param then
        return SceneUtils.BackwardBattleConditionResult.AlwaysCant
      elseif 2 == param then
        return SceneUtils.BackwardBattleConditionResult.ByAngle
      end
    end
  end
  return SceneUtils.BackwardBattleConditionResult.ByAngleAndControlFlag
end

function SceneUtils.CanEnterCatchInBack(sceneNpc)
  if GlobalConfig.DisableBackwardAIFilter then
    return true
  end
  return sceneNpc.AIComponent and sceneNpc.AIComponent:HasControlFlags(Enum.SceneAiControlFlags.SACF_ENABLE_BACKSTUB)
end

local function GetCosineConf(key)
  local conf = _G.DataConfigManager:GetBattleGlobalConfig(key)
  local angle = conf and conf.num or 0
  return math.cos(math.rad(angle))
end

local bReadFromConfig = false
local ThrowBackCosine, TouchBackCosine

local function CheckBackwardBattleByAngle(npc, forward, type)
  if not bReadFromConfig then
    ThrowBackCosine = GetCosineConf("backstab_throwbattle_trigger_angle")
    TouchBackCosine = GetCosineConf("backstab_touchbattle_trigger_angle")
    bReadFromConfig = true
  end
  type = type or 1
  local CheckCosine = 1 == type and ThrowBackCosine or TouchBackCosine
  local npcForward = npc:GetForwardVector()
  forward:Normalize()
  local dot = npcForward:Dot(forward)
  if GlobalConfig.DebugLuaBTree then
    local result = CheckCosine <= dot
    local pos = npc:GetActorLocation()
    UE.UKismetSystemLibrary.Abs_DrawDebugLine(UE4Helper.GetCurrentWorld(), pos, pos + npcForward * 200, UE4.FLinearColor(1, 1, 0, 1), 10, 5)
    UE.UKismetSystemLibrary.Abs_DrawDebugLine(UE4Helper.GetCurrentWorld(), pos, pos - forward * 200, result and UE4.FLinearColor(0, 1, 0, 1) or UE4.FLinearColor(1, 0, 0, 1), 10, 5)
    local l = npcForward:RotateAngleAxis(math.deg(math.acos(CheckCosine)), UE4Helper.UpVector)
    local r = npcForward:RotateAngleAxis(-math.deg(math.acos(CheckCosine)), UE4Helper.UpVector)
    UE.UKismetSystemLibrary.Abs_DrawDebugLine(UE4Helper.GetCurrentWorld(), pos, pos - l * 200, UE4.FLinearColor(1, 0, 0, 1), 10, 5)
    UE.UKismetSystemLibrary.Abs_DrawDebugLine(UE4Helper.GetCurrentWorld(), pos, pos - r * 200, UE4.FLinearColor(1, 0, 0, 1), 10, 5)
  end
  return CheckCosine <= dot
end

local function CheckBackwardBattleByAIControlFlag(npc)
  if GlobalConfig.DisableBackwardAIFilter then
    return true
  end
  return npc.AIComponent and npc.AIComponent:HasControlFlags(Enum.SceneAiControlFlags.SACF_ENABLE_BACKSTUB)
end

function SceneUtils.TriggerBackwardBattle(npc, forward, type, ScenePet)
  local condition = SceneUtils.GetBackwardBattleCondition(npc, type, ScenePet)
  if condition == SceneUtils.BackwardBattleConditionResult.AlwaysCant then
    return false, true
  elseif condition == SceneUtils.BackwardBattleConditionResult.AlwaysCan then
    return true, true
  elseif condition == SceneUtils.BackwardBattleConditionResult.ByAngle then
    return CheckBackwardBattleByAngle(npc, forward, type), true
  elseif condition == SceneUtils.BackwardBattleConditionResult.ByAngleAndControlFlag then
    return CheckBackwardBattleByAIControlFlag(npc) and CheckBackwardBattleByAngle(npc, forward, type), false
  end
  return false, false
end

function SceneUtils.TriggerBackwardCatch(npc, forward)
  if not SceneUtils.CanEnterCatchInBack(npc) then
    return false
  end
  if not bReadFromConfig then
    ThrowBackCosine = GetCosineConf("backstab_throwbattle_trigger_angle")
    TouchBackCosine = GetCosineConf("backstab_touchbattle_trigger_angle")
    bReadFromConfig = true
  end
  local CheckCosine = ThrowBackCosine
  local npcForward = npc:GetForwardVector()
  forward:Normalize()
  local dot = npcForward:Dot(forward)
  if GlobalConfig.DebugLuaBTree then
    local result = CheckCosine <= dot
    local pos = npc:GetActorLocation()
    UE.UKismetSystemLibrary.Abs_DrawDebugLine(UE4Helper.GetCurrentWorld(), pos, pos + npcForward * 200, UE4.FLinearColor(1, 1, 0, 1), 10, 5)
    UE.UKismetSystemLibrary.Abs_DrawDebugLine(UE4Helper.GetCurrentWorld(), pos, pos - forward * 200, result and UE4.FLinearColor(0, 1, 0, 1) or UE4.FLinearColor(1, 0, 0, 1), 10, 5)
    local l = npcForward:RotateAngleAxis(math.deg(math.acos(CheckCosine)), UE4Helper.UpVector)
    local r = npcForward:RotateAngleAxis(-math.deg(math.acos(CheckCosine)), UE4Helper.UpVector)
    UE.UKismetSystemLibrary.Abs_DrawDebugLine(UE4Helper.GetCurrentWorld(), pos, pos - l * 200, UE4.FLinearColor(1, 0, 0, 1), 10, 5)
    UE.UKismetSystemLibrary.Abs_DrawDebugLine(UE4Helper.GetCurrentWorld(), pos, pos - r * 200, UE4.FLinearColor(1, 0, 0, 1), 10, 5)
  end
  return CheckCosine <= dot
end

local function GetPos(Info)
  if Info.avatar then
    return Info.avatar.base.pt.pos
  end
  if Info.npc then
    return Info.npc.base.pt.pos
  end
  return {
    x = 0,
    y = 0,
    z = 0
  }
end

local function Dist(P1, P2)
  local X = P1.x - P2.x
  local Y = P1.y - P2.y
  local Z = P1.z - P2.z
  return X * X + Y * Y + Z * Z
end

function SceneUtils.SortActorsByDistanceToPlayer(Actors, PlayerPos)
  table.sort(Actors, function(A, B)
    local PA = GetPos(A)
    local PB = GetPos(B)
    local DA = Dist(PA, PlayerPos)
    local DB = Dist(PB, PlayerPos)
    return DA < DB
  end)
end

function SceneUtils.GetYawFromDir(X, Y)
  local Yaw = math.atan(Y, X) * (180 / math.pi)
  local Rotator = UE.FRotator(0, Yaw, 0)
  return Rotator
end

function SceneUtils.StringToTransform(Param)
  local Segments = string.split(Param, ";")
  local X = tonumber(Segments[1]) or 0
  local Y = tonumber(Segments[2]) or 0
  local Z = tonumber(Segments[3]) or 0
  local Roll = tonumber(Segments[4]) or 0
  local Pitch = tonumber(Segments[5]) or 0
  local Yaw = tonumber(Segments[6]) or 0
  local Rot = UE.FRotator(Pitch, Yaw, Roll)
  return UE.FTransform(Rot:ToQuat(), UE.FVector(X, Y, Z))
end

function SceneUtils.RequestPlayerUpdateEnvInfo()
  local player = NRCModeManager:DoCmd(PlayerModuleCmd.GET_LOCAL_PLAYER)
  if player and player.viewObj then
    local envInfo = player.viewObj:GetComponentByClass(UE.UCharacterEnvInfoComponent)
    if envInfo then
      envInfo:RequestUpdateSurface()
    end
  end
end

function SceneUtils.CalcLaunchVelocity(source, target, height, gravity)
  gravity = math.abs(gravity or 980)
  local dir2d = target - source
  dir2d.Z = 0
  dir2d:Normalize()
  local dist2d = target:Dist2D(source)
  local heightDiff = target.Z - source.Z
  local H1 = height
  local H2 = H1 - heightDiff
  if H2 < 0 or H1 < 0 then
    H1 = heightDiff > 0 and heightDiff or 0
    H2 = heightDiff > 0 and 0 or -heightDiff
  end
  local t1 = math.sqrt(H1 / gravity * 2)
  local t2 = math.sqrt(H2 / gravity * 2)
  local launchVel = dir2d * (dist2d / (t1 + t2))
  launchVel.Z = 0 == H1 and 0 or 2 * H1 / t1
  return launchVel
end

function SceneUtils.GetWorldOriginTransform()
  return UE.FTransform(UE.FRotator(0, 0, 0):ToQuat(), SceneUtils.ConvertAbsoluteToRelative(UE.FVector(0, 0, 0)))
end

function SceneUtils.SetupSpotLight(npc, path)
  if not npc then
    return
  end
  local View = npc.viewObj
  if not View then
    return
  end
  local Comp = rawget(View, "SpotLight")
  if string.IsNilOrEmpty(path) then
    if Comp then
      Comp:SetChildActorClass(nil)
    end
  elseif not Comp then
    local Quat = UE.FRotator():ToQuat()
    Comp = View:AddComponentByClass(UE.UNRCChildActorComponent, false, UE.FTransform(Quat, _G.FVectorZero), false)
    Comp:SetPath(path)
    rawset(View, "SpotLight", Comp)
  end
end

function SceneUtils.IsInPikaShop()
  local SceneModule = _G.NRCModuleManager:GetModule("SceneModule")
  if SceneModule then
    return SceneModule:IsInPikaShop()
  else
    return false
  end
end

function SceneUtils:DebugOpenCollision(actor)
  if not UE.UObject.IsValid(actor) or not actor.GetComponentsByTag then
    Log.Error("SceneUtils:DebugOpenCollision: actor is invalid!")
    return
  end
  local tag = "SkillHit"
  local hitComps = actor:GetComponentsByTag(UE4.UPrimitiveComponent, tag)
  for idx = 1, hitComps:Length() do
    local hitComp = hitComps:Get(idx)
    hitComp:SetCollisionProfileName(tag)
    hitComp:SetCollisionEnabled(UE.ECollisionEnabled.QueryOnly)
    hitComp:SetGenerateOverlapEvents(true)
  end
  tag = "SkillHited"
  hitComps = actor:GetComponentsByTag(UE4.UPrimitiveComponent, tag)
  for idx = 1, hitComps:Length() do
    local hitComp = hitComps:Get(idx)
    hitComp:SetCollisionProfileName(tag)
    hitComp:SetCollisionEnabled(UE.ECollisionEnabled.QueryOnly)
    hitComp:SetGenerateOverlapEvents(true)
  end
  hitComps = actor:K2_GetComponentsByClass(UE4.UPrimitiveComponent)
  for idx = 1, hitComps:Length() do
    local hitComp = hitComps:Get(idx)
    if hitComp:GetName() == "HitedComponent" then
      hitComp:SetCollisionProfileName("SkillHited")
      hitComp:SetCollisionEnabled(UE.ECollisionEnabled.QueryOnly)
      hitComp:SetGenerateOverlapEvents(true)
    end
  end
end

function SceneUtils.NormNPCLightingChannels(actor)
  if actor and UE.UObject.IsValid(actor) then
    if actor:IsA(UE.ANPCBaseCharacter) then
      UE4.UNRCStatics.SetSixLightingChannels(actor, true, false, true, false, true, false, false)
    elseif actor:IsA(UE.ANPCBaseActor) then
      UE4.UNRCStatics.SetSixLightingChannels(actor, true, false, false, true, false, false, false)
    end
  end
end

local AutoHoming = false
local AutoHomingTargetID = 0

function SceneUtils.QueryNPCInRange(Location)
  if 0 ~= AutoHomingTargetID then
    local HomingTarget = _G.NRCModuleManager:DoCmd(_G.NPCModuleCmd.GetNpcByServerID, AutoHomingTargetID)
    if HomingTarget and HomingTarget.viewObj then
      return HomingTarget.viewObj
    end
  end
  local World = _G.UE4Helper.GetCurrentWorld()
  local Klass = UE4.UClass.Load("/Game/NewRoco/Modules/Core/NPC/BP_NPCCharacter")
  local ResultArray = UE4.TArray(UE.AActor)
  local Success = UE.UKismetSystemLibrary.Abs_SphereOverlapActors(World, Location, 1000, {
    UE.EObjectTypeQuery.ObjectTypeQuery3
  }, Klass, nil, ResultArray)
  if Success then
    local NearDist = 2250000
    local NearNPC
    for _, Actor in tpairs(ResultArray) do
      local Dist = UE4.FVector.DistSquared(Location, Actor:Abs_K2_GetActorLocation())
      if NearDist > Dist then
        NearDist = Dist
        NearNPC = Actor
      end
      return Actor
    end
    return NearNPC
  end
  return nil
end

function SceneUtils.SetAutoHomingTargetID(ID)
  AutoHomingTargetID = ID
end

function SceneUtils.SetAutoHoming(value)
  AutoHoming = value
end

function SceneUtils.GetAutoHoming()
  return AutoHoming
end

function SceneUtils.WorldCombatGetPosInLand(Pos, Runner, exclude, excludeAdd, channel, isDown, bWaterAsLand, debug, defaultWorld)
  if not Runner then
    return Pos
  end
  local result = SceneUtils.GetPosInLand(Pos, Runner:GetScaledHalfHeight(), Runner:GetScaledHalfHeight(), 5000, exclude, excludeAdd, channel, isDown, bWaterAsLand, debug, defaultWorld)
  result = result or Pos
  return result
end

local HOME_SCENE_ID = 301

function SceneUtils.InHomeScene()
  return SceneUtils.GetSceneID() == HOME_SCENE_ID
end

function SceneUtils.IsNearlyZero(InVec, Tolerance)
  if not InVec then
    return true
  end
  Tolerance = Tolerance or 1.0E-4
  local SizeSquared = (InVec.x or 0) * (InVec.x or 0) + (InVec.y or 0) * (InVec.y or 0) + (InVec.z or 0) * (InVec.z or 0)
  return SizeSquared < Tolerance * Tolerance
end

function SceneUtils.ParseStrRGB(str)
  if nil == str or not type(str) == "string" then
    return
  end
  local str_rgb = string.split(str, ";")
  if 3 == not #str_rgb and 4 == not #str_rgb then
    Log.DebugFormat("string %s do not contains 3/4 numbers", str)
    return
  end
  local r = tonumber(str_rgb[1])
  local g = tonumber(str_rgb[2])
  local b = tonumber(str_rgb[3])
  local a = #str_rgb > 3 and tonumber(str_rgb[4]) or 0
  if r and g and b then
    return UE4.FLinearColor(r / 255.0, g / 255.0, b / 255.0, a / 255.0)
  end
  Log.DebugFormat("string %s do not contains 3/4 numbers", str)
  return
end

local HALF_HEIGHT = 85

function SceneUtils.ClientPos2PlayerPos(clientPos, inPlayerPos)
  if not clientPos then
    Log.Error("SceneUtils:ClientPos2PlayerPos clientPos is nil")
    return nil
  end
  if not inPlayerPos then
    inPlayerPos = UE.FVector(clientPos.X, clientPos.Y, clientPos.Z + HALF_HEIGHT)
  else
    inPlayerPos.X = clientPos.X
    inPlayerPos.Y = clientPos.Y
    inPlayerPos.Z = clientPos.Z + HALF_HEIGHT
  end
  return inPlayerPos
end

function SceneUtils.PlayerPos2ClientPos(playerPos, inClientPos)
  if not playerPos then
    Log.Error("SceneUtils:PlayerPos2ClientPos playerPos is nil")
    return nil
  end
  if not inClientPos then
    inClientPos = UE.FVector(playerPos.X, playerPos.Y, playerPos.Z - HALF_HEIGHT)
  else
    inClientPos.X = playerPos.X
    inClientPos.Y = playerPos.Y
    inClientPos.Z = playerPos.Z - HALF_HEIGHT
  end
  return inClientPos
end

function SceneUtils.ServerPos2PlayerPos(serverPos, factor, inPlayerPos)
  local clientPos = SceneUtils.ServerPos2ClientPos(serverPos, factor, inPlayerPos)
  return SceneUtils.ClientPos2PlayerPos(clientPos, inPlayerPos)
end

function SceneUtils.PlayerPos2ServerPos(playerPos, factor, InServePos)
  local clientPos = SceneUtils.PlayerPos2ClientPos(playerPos)
  return SceneUtils.ClientPos2ServerPos(clientPos, factor, InServePos)
end

function SceneUtils.CalculateFlyBackPlayRate(Actor1, Actor2, SkillDuration, Config)
  if not UE4.UObject.IsValid(Actor1) or not UE4.UObject.IsValid(Actor2) then
    return 1.0
  end
  local Location1 = Actor1:K2_GetActorLocation()
  local Location2 = Actor2:K2_GetActorLocation()
  if not Location1 or not Location2 then
    return 1.0
  end
  local Distance = (Location1 - Location2):Size()
  SkillDuration = SkillDuration or 1.5
  local Speed = Config and Config.Speed or 200.0
  local MaxFlyTime = Config and Config.MaxFlyTime or 1.5
  local MinFlyTime = Config and Config.MinFlyTime or 0.3
  local MaxPlayRate = Config and Config.MaxPlayRate or 5.0
  local MinPlayRate = Config and Config.MinPlayRate or 1.0
  local FlyTime = Distance / Speed
  FlyTime = math.clamp(FlyTime, MinFlyTime, MaxFlyTime)
  local PlayRate = SkillDuration / FlyTime
  PlayRate = math.clamp(PlayRate, MinPlayRate, MaxPlayRate)
  return PlayRate
end

return SceneUtils

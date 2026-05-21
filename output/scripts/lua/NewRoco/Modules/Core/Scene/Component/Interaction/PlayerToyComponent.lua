local Base = require("NewRoco.Modules.Core.Scene.Component.ActorComponent")
local SceneUtils = require("NewRoco.Modules.Core.Scene.Common.SceneUtils")
local RocoSkillProxy = require("NewRoco.Utils.RocoSkillProxy")
local PlayerModuleEvent = require("NewRoco.Modules.Core.PlayerModule.PlayerModuleEvent")
local NPCModuleEvent = require("NewRoco.Modules.Core.NPC.NPCModuleEvent")
local NPCModuleEnum = require("NewRoco.Modules.Core.NPC.NPCModuleEnum")
local HomeUtils = require("NewRoco.Modules.System.Home.IndoorSandbox.HomeUtils")
local SceneEvent = require("NewRoco.Modules.Core.Scene.Common.SceneEvent")
local NotIgnoreActorTags = {
  "MagicMessage",
  "MagicVideo",
  "PlayerToy"
}
local ToyPlaceResult = {
  Invalid = -1,
  Valid = 0,
  UnInited = 1,
  AreaBan = 10,
  StackedNpc = 20,
  Blocked = 30,
  OverlapStatic = 40,
  OverlapNpc = 50,
  HeightDiffTooMuch = 60,
  WaterSurface = 70
}
local ToyPlaceTipsType = {
  UnInited = 0,
  LandInvalid = 10,
  NotPlaneness = 20
}
local PlaceResultToTipsType = {
  [ToyPlaceResult.UnInited] = ToyPlaceTipsType.UnInited,
  [ToyPlaceResult.AreaBan] = ToyPlaceTipsType.LandInvalid,
  [ToyPlaceResult.StackedNpc] = ToyPlaceTipsType.LandInvalid,
  [ToyPlaceResult.Blocked] = ToyPlaceTipsType.LandInvalid,
  [ToyPlaceResult.OverlapStatic] = ToyPlaceTipsType.NotPlaneness,
  [ToyPlaceResult.OverlapNpc] = ToyPlaceTipsType.NotPlaneness,
  [ToyPlaceResult.HeightDiffTooMuch] = ToyPlaceTipsType.LandInvalid,
  [ToyPlaceResult.WaterSurface] = ToyPlaceTipsType.LandInvalid
}
local PlayerToyComponent = Base:Extend("PlayerToyComponent")
local FreePlacingMatAssetKeyValid = "PlayerToyComponent_FreePlacingValid"
local FreePlacingMatAssetKeyInvalid = "PlayerToyComponent_FreePlacingInvalid"

function PlayerToyComponent.GetPreloadList()
  local list = {}
  list[FreePlacingMatAssetKeyValid] = "/Game/ArtRes/Effects/Texture/Color/MeshMaterial/MI_Color_ZX_002M1.MI_Color_ZX_002M1"
  list[FreePlacingMatAssetKeyInvalid] = "/Game/ArtRes/Effects/Texture/Color/MeshMaterial/MI_Color_ZX_002M2.MI_Color_ZX_002M2"
  return list
end

function PlayerToyComponent:Attach(owner)
  Base.Attach(self, owner)
  self.PropID = nil
  self.RegisteredToys = {}
  WeakTable(self.RegisteredToys)
  Log.Debug("PlayerToyComponent:Attach")
  self.AreaQueryManager = UE4.UAreaQueryManager.Get(_G.UE4Helper.GetCurrentWorld())
  self.AbilityBanManager = nil
  local areaModule = _G.NRCModuleManager:GetModule("AreaAndZoneModule")
  if areaModule then
    self.AbilityBanManager = areaModule:GetAbilityBanManager()
  end
  self.LandTraceExtent = UE4.FVector(0, 0, 150)
  self.LandTraceChannel = UE4.UNRCStatics.ConvertToTraceChannel(UE4.ECollisionChannel.ECC_GameTraceChannel5)
  self.LineTraceObjectTypes = {
    UE4.ECollisionChannel.ECC_WorldStatic,
    UE4.ECollisionChannel.ECC_WorldDynamic,
    UE4.ECollisionChannel.ECC_Camera,
    UE4.ECollisionChannel.ECC_Pawn,
    UE4.ECollisionChannel.ECC_GameTraceChannel7,
    UE4.ECollisionChannel.ECC_GameTraceChannel10,
    UE4.ECollisionChannel.ECC_GameTraceChannel12
  }
  self.BoxTraceObjectTypes = {
    UE4.EObjectTypeQuery.WorldStatic,
    UE4.EObjectTypeQuery.WorldDynamic,
    UE4.EObjectTypeQuery.Character,
    UE4.EObjectTypeQuery.Pawn,
    UE4.EObjectTypeQuery.Vehicle,
    UE4.EObjectTypeQuery.Tree
  }
  self.NPCTraceObjectTypes = {
    UE4.EObjectTypeQuery.WorldDynamic,
    UE4.EObjectTypeQuery.Character,
    UE4.EObjectTypeQuery.Pawn
  }
  self.QueryParams = UE4.FNRCollisionQueryParams()
  self.HeightOffsetAllowance = 100
  local config = _G.DataConfigManager:GetGlobalConfigByKeyType("prop_z_offset_limit", _G.DataConfigManager.ConfigTableId.GLOBAL_CONFIG)
  if config and config.num then
    self.HeightOffsetAllowance = config.num
  end
  self.CreateDistance = 300
  self:RegisterEvents()
end

function PlayerToyComponent:RegisterEvents()
  NRCEventCenter:RegisterEvent("PlayerToyComponent", self, SceneEvent.OnEnterSceneFinishNtyAckEnd, self.OnPlayerTeleportFinish)
  self.owner:AddEventListener(self, PlayerModuleEvent.ON_APPLY_STATUS, self.OnApplyStatus)
end

function PlayerToyComponent:DeAttach()
  self.PropID = nil
  self:UnRegisterEvents()
  Log.Debug("PlayerToyComponent:DeAttach")
  Base.DeAttach(self)
end

function PlayerToyComponent:UnRegisterEvents()
  NRCEventCenter:UnRegisterEvent(self, SceneEvent.OnEnterSceneFinishNtyAckEnd, self.OnPlayerTeleportFinish)
  self.owner:RemoveEventListener(self, PlayerModuleEvent.ON_APPLY_STATUS, self.OnApplyStatus)
end

function PlayerToyComponent:OnApplyStatus(status, statusValue, opCode, customParam)
  if status == Enum.WorldPlayerStatusType.WPST_TRANSFORM or status == Enum.WorldPlayerStatusType.WPST_SWIMMING then
    _G.NRCModuleManager:DoCmd(_G.MainUIModuleCmd.ClosePropPlacementPanel)
  end
end

function PlayerToyComponent:Update(deltaTime)
  self:UpdatePreviewPropNpc(deltaTime)
end

function PlayerToyComponent:CreateRolePlayProp(PropID)
  self.PropID = PropID
  if PropID then
    self:QueryPosForProp()
  end
end

function PlayerToyComponent:RecycleRolePlayProp(SeatID, CreatorUin)
  local NPCModule = _G.NRCModuleManager:GetModule("NPCModule")
  if not NPCModule then
    Log.Error("PlayerToyComponent:RecycleRolePlayProp NPCModule not found")
    return
  end
  local NPC = NPCModule:OnFindNPCByConfigIDAndUin(SeatID, CreatorUin)
  if NPC then
    if NPC.notDestroyFlag then
      _G.NRCModuleManager:DoCmd(_G.TipsModuleCmd.TopHud_ShowTips, LuaText.retake_ban)
      _G.NRCModuleManager:DoCmd(_G.RolePlayModuleCmd.OnRecyclePropResponse, false)
      return
    end
    self:OnPlayerRecycleRoleplayProp(NPC.serverData.base.actor_id)
  end
end

function PlayerToyComponent:QueryPosForProp()
  local MovementBaseComp = self.owner.viewObj.BasedMovement.MovementBase
  if MovementBaseComp then
    local MovementBaseActor = MovementBaseComp:GetOwner()
    if MovementBaseActor and MovementBaseActor:IsA(UE.ANPCSceneSkeletalMeshActor) then
      _G.NRCModuleManager:DoCmd(_G.TipsModuleCmd.TopHud_ShowTips, LuaText.put_prop_fail_b)
      _G.NRCModuleManager:DoCmd(_G.RolePlayModuleCmd.OnPutPropResponse, false)
      return
    end
  end
  local NPCModule = _G.NRCModuleManager:GetModule("NPCModule")
  if not NPCModule then
    Log.Error("PlayerToyComponent:QueryPosForSeat NPCModule not found")
    return
  end
  local Runner = NPCModule.EQSManager:Get("SceneSeat")
  local Request = Runner:MakeRequest(nil, self.owner.viewObj)
  local QueryID = -1
  QueryID = Runner:StartQueryWithRequest(UE.EEnvQueryRunMode.AllMatching, Request, self, self.OnQueryPosForSeatFinished)
  if QueryID < 0 then
    Log.Error("QueryPosForSeat failed!")
  end
end

function PlayerToyComponent:OnQueryPosForSeatFinished(Result)
  if not (Result and Result.bFinished) or not Result.bSuccess then
    Log.Debug("PlayerToyComponent:OnQueryPosForSeatFinished. not Result, not bFinished, not bSuccess")
    _G.NRCModuleManager:DoCmd(_G.TipsModuleCmd.TopHud_ShowTips, LuaText.put_prop_fail_a)
    _G.NRCModuleManager:DoCmd(_G.RolePlayModuleCmd.OnPutPropResponse, false)
    return
  end
  if _G.GlobalConfig.bDebugSceneSeatEQS then
    self:DebugSceneSeatEQS(Result)
  end
  if 0 == Result.ResultLocations:Num() then
    Log.Debug("PlayerToyComponent:OnQueryPosForSeatFinished. Result.ResultLocations:Num() == 0")
    _G.NRCModuleManager:DoCmd(_G.TipsModuleCmd.TopHud_ShowTips, LuaText.put_prop_fail_a)
    _G.NRCModuleManager:DoCmd(_G.RolePlayModuleCmd.OnPutPropResponse, false)
    return
  end
  local Conf = _G.DataConfigManager:GetRoleplayPropConf(self.PropID)
  if not Conf then
    Log.Error("==PlayerToyComponent:OnQueryPosForSeatFinished==Conf is nil", self.PropID)
    _G.NRCModuleManager:DoCmd(_G.RolePlayModuleCmd.OnPutPropResponse, false)
    return
  end
  local Box = {}
  if Conf.prop_eqs_box_custom and #Conf.prop_eqs_box_custom > 0 then
    for i, v in ipairs(Conf.prop_eqs_box_custom) do
      table.insert(Box, tonumber(v))
    end
  else
    local ExportConf = _G.DataConfigManager:GetEqsBoxExport(self.PropID)
    if ExportConf and ExportConf.prop_eqs_box and #ExportConf.prop_eqs_box > 0 then
      for i, v in ipairs(ExportConf.prop_eqs_box) do
        table.insert(Box, tonumber(v))
      end
    end
  end
  if 3 ~= #Box then
    Log.Error("==PlayerToyComponent:OnQueryPosForSeatFinished==Box is not 3", self.PropID)
    _G.NRCModuleManager:DoCmd(_G.RolePlayModuleCmd.OnPutPropResponse, false)
    return
  end
  local PlayerAbsoluteLocation = self.owner:GetActorLocation()
  local PlayerLocation = SceneUtils.ConvertAbsoluteToRelative(PlayerAbsoluteLocation)
  local AllPlayer = _G.NRCModuleManager:DoCmd(_G.PlayerModuleCmd.GET_ALL_PLAYER)
  local IgnoreActor = {}
  for i, v in ipairs(AllPlayer) do
    table.insert(IgnoreActor, v.viewObj)
  end
  local SuccessPoint = {}
  local Offset = UE4.FVector(0, 0, Box[3] + (Conf.lift_box or 0))
  local Extent = UE4.FVector(Box[1], Box[2], Box[3])
  local drawDebugType = UE4.EDrawDebugTrace.None
  local traceColor, traceHitColor, drawTime
  if _G.GlobalConfig.bDebugSceneSeatEQS then
    drawDebugType = UE4.EDrawDebugTrace.ForDuration
    traceColor = UE4.FLinearColor(0.3, 1, 0.1, 1)
    traceHitColor = UE4.FLinearColor(0.9, 0.2, 0.2, 1)
    drawTime = 12.0
  end
  self.QueryParams.ActorsToIgnore = IgnoreActor
  local FailedReason = 0
  for i, ResultLocation in tpairs(Result.ResultLocations) do
    local bQuerySuccess = Result.ItemSuccess:Get(i)
    if bQuerySuccess then
      local BoxLocation = ResultLocation + Offset
      local AbsoluteLocation = SceneUtils.ConvertRelativeToAbsolute(BoxLocation)
      local Dir = PlayerLocation - BoxLocation
      Dir:Normalize()
      local Rotator = UE.UKismetMathLibrary.MakeRotFromX(Dir)
      local Rot = UE.FRotator(0, (Rotator.Yaw - 90 + 360) % 3600, 0)
      local tag = string.format("%d", i)
      local validType = self:GetLocationPlaceResult(ResultLocation, BoxLocation, AbsoluteLocation, PlayerLocation, Extent, Rot, tag, drawDebugType, traceColor, traceHitColor, drawTime)
      local tipsType = self:GetTipsType(validType)
      if tipsType == ToyPlaceTipsType.LandInvalid then
        FailedReason = FailedReason + 1
      elseif tipsType == ToyPlaceTipsType.NotPlaneness then
        FailedReason = FailedReason - 1
      end
      if validType ~= ToyPlaceResult.Valid then
      else
        local Point = ProtoMessage:newPoint()
        Point.pos.x = math.round(AbsoluteLocation.X)
        Point.pos.y = math.round(AbsoluteLocation.Y)
        Point.pos.z = math.round(AbsoluteLocation.Z)
        Point.dir.x = 0
        Point.dir.y = 0
        Point.dir.z = math.round(Rot.Yaw * 10)
        table.insert(SuccessPoint, Point)
      end
    end
    if _G.GlobalConfig.bDebugSceneSeatEQS then
      UE4.UKismetSystemLibrary.DrawDebugString(_G.UE4Helper.GetCurrentWorld(), BoxLocation, i, nil, UE4.FLinearColor(1, 1, 1, 1), drawTime)
    end
  end
  if 0 == #SuccessPoint then
    _G.NRCModuleManager:DoCmd(_G.TipsModuleCmd.TopHud_ShowTips, FailedReason < 0 and LuaText.put_prop_fail_a or LuaText.put_prop_fail_b)
    _G.NRCModuleManager:DoCmd(_G.RolePlayModuleCmd.OnPutPropResponse, false)
    return
  end
  local Request = _G.ProtoMessage:newZoneSceneCreateRoleplayPropReq()
  Request.create_pts = SuccessPoint
  Request.roleplay_prop_config_id = self.PropID or 68001
  _G.ZoneServer:SendWithHandler(ProtoCMD.ZoneSvrCmd.ZONE_SCENE_CREATE_ROLEPLAY_PROP_REQ, Request, self, self.OnZoneSceneCreateRoleplayPropRsp, nil, true)
end

function PlayerToyComponent:CheckComponentIsNpc(component)
  if not component or not UE4.UObject.IsValid(component) then
    return false
  end
  local actor = component:GetOwner()
  if not actor or not UE4.UObject.IsValid(actor) then
    return false
  end
  for _, tag in pairs(NotIgnoreActorTags) do
    if actor:ActorHasTag(tag) then
      return true
    end
  end
  local collisionEnabled = component:GetCollisionEnabled()
  if collisionEnabled == UE4.ECollisionEnabled.QueryOnly then
    if actor.BoundingRadius then
      return true
    end
    return false
  end
  if actor:IsA(UE4.ANPCBaseActor) then
    return true
  end
  return false
end

function PlayerToyComponent:CheckComponentIsValid(component, objectTypes)
  if not component or not UE4.UObject.IsValid(component) then
    return false
  end
  local collisionEnabled = component:GetCollisionEnabled()
  if collisionEnabled == UE4.ECollisionEnabled.QueryOnly then
    return false
  end
  local actor = component:GetOwner()
  if actor and UE4.UObject.IsValid(actor) then
    for _, tag in pairs(NotIgnoreActorTags) do
      if actor:ActorHasTag(tag) then
        return true
      end
    end
  end
  if objectTypes then
    for _, channel in pairs(objectTypes) do
      if component:GetCollisionResponseToChannel(channel) == UE4.ECollisionResponse.ECR_Block then
        return true
      end
    end
  end
  return false
end

function PlayerToyComponent:GetLocationPlaceResult(location, boxLocation, absLocation, playerLocation, boxExtent, boxRot, tag, drawDebugType, traceColor, traceHitColor, drawTime)
  tag = tag or ""
  if self.AreaQueryManager and self.AbilityBanManager then
    local areas = self.AreaQueryManager:QueryAreasAtPosition(absLocation)
    local bIsBanned, bannedAreaId = self.AbilityBanManager:GetPropsIsBannedInAreasTArray(self.PropID, areas)
    if bIsBanned then
      if _G.GlobalConfig.bDebugSceneSeatEQS then
        UE4.UKismetSystemLibrary.DrawDebugString(_G.UE4Helper.GetCurrentWorld(), boxLocation, string.format("\229\140\186\229\159\159\231\166\129\231\148\168:%d", bannedAreaId), nil, UE4.FLinearColor(0.9, 0.2, 0.1, 0.8), drawTime)
      end
      return ToyPlaceResult.AreaBan
    end
  end
  self.QueryParams.OwnerTag = "SceneSeat_" .. tag
  local surfaceType = UE.UNRCStatics.CheckSurfaceTypeAtLocation(self.owner.viewObj, location, 200)
  if 2 == surfaceType then
    if _G.GlobalConfig.bDebugSceneSeatEQS then
      UE4.UKismetSystemLibrary.DrawDebugSphere(_G.UE4Helper.GetCurrentWorld(), boxLocation, 10, 24, UE.FLinearColor(0.1, 0.1, 1, 1), drawTime, 2)
    end
    return ToyPlaceResult.WaterSurface
  end
  self.QueryParams.TraceTag = "Land"
  local landHitResults, bLandHitSuccess = UE4.UNRCTraceLibrary.LineTraceMulti(_G.UE4Helper.GetCurrentWorld(), location + self.LandTraceExtent, location - self.LandTraceExtent, self.LandTraceChannel, self.QueryParams, nil, drawDebugType, traceColor, traceHitColor, drawTime)
  if bLandHitSuccess and landHitResults then
    for _, hitResult in tpairs(landHitResults) do
      if self:CheckComponentIsNpc(hitResult.Component) then
        if _G.GlobalConfig.bDebugSceneSeatEQS then
          UE4.UKismetSystemLibrary.DrawDebugString(_G.UE4Helper.GetCurrentWorld(), hitResult.ImpactPoint, UE4.UKismetSystemLibrary.GetDisplayName(hitResult.Component), nil, UE4.FLinearColor(0.8, 0.2, 0.5, 0.8), drawTime)
        end
        return ToyPlaceResult.StackedNpc
      end
    end
  end
  self.QueryParams.TraceTag = "LineHit"
  local lineHitResults, bLineHitSuccess = UE4.UNRCTraceLibrary.LineTraceMultiForObjects(_G.UE4Helper.GetCurrentWorld(), playerLocation, boxLocation, self.LineTraceObjectTypes, self.QueryParams, nil, drawDebugType, traceColor, traceHitColor, drawTime)
  if bLineHitSuccess and lineHitResults then
    for _, hitResult in tpairs(lineHitResults) do
      if self:CheckComponentIsValid(hitResult.Component, self.LineTraceObjectTypes) then
        if _G.GlobalConfig.bDebugSceneSeatEQS then
          UE4.UKismetSystemLibrary.DrawDebugString(_G.UE4Helper.GetCurrentWorld(), hitResult.ImpactPoint, UE4.UKismetSystemLibrary.GetDisplayName(hitResult.Component), nil, UE4.FLinearColor(1, 0.2, 0, 0.8), drawTime)
        end
        return ToyPlaceResult.Blocked
      end
    end
  end
  self.QueryParams.TraceTag = "BoxOverlap"
  local components = UE4.UNRCTraceLibrary.BoxOverlapComponents(_G.UE4Helper.GetCurrentWorld(), boxLocation, boxExtent, boxRot, self.BoxTraceObjectTypes, nil, self.QueryParams, nil, drawDebugType, traceColor, traceHitColor, drawTime)
  for compIdx, comp in tpairs(components) do
    if self:CheckComponentIsValid(comp, self.LineTraceObjectTypes) then
      if _G.GlobalConfig.bDebugSceneSeatEQS then
        UE4.UKismetSystemLibrary.DrawDebugString(_G.UE4Helper.GetCurrentWorld(), boxLocation + UE4.FVector(0, 0, compIdx * 5), UE4.UKismetSystemLibrary.GetDisplayName(comp), nil, UE4.FLinearColor(1, 0.2, 0, 0.8), drawTime)
      end
      return ToyPlaceResult.OverlapStatic
    end
  end
  self.QueryParams.TraceTag = "NpcOverlap"
  local NpcBoxOffset = UE4.FVector(0, 0, boxExtent.Z / 2.0)
  local npcComponents = UE4.UNRCTraceLibrary.BoxOverlapComponents(_G.UE4Helper.GetCurrentWorld(), location + NpcBoxOffset, boxExtent, boxRot, self.NPCTraceObjectTypes, nil, self.QueryParams, nil, drawDebugType, traceColor, traceHitColor, drawTime)
  for compIdx, comp in tpairs(npcComponents) do
    if self:CheckComponentIsNpc(comp) then
      if _G.GlobalConfig.bDebugSceneSeatEQS then
        UE4.UKismetSystemLibrary.DrawDebugString(_G.UE4Helper.GetCurrentWorld(), location + UE4.FVector(0, 0, compIdx * 5), UE4.UKismetSystemLibrary.GetDisplayName(comp), nil, UE4.FLinearColor(0.4, 0.2, 0.6, 0.8), drawTime)
      end
      Log.Debug("PlayerToyComponent:OnQueryPosForSeatFinished overlap npc", tag, UE4.UKismetSystemLibrary.GetDisplayName(comp))
      return ToyPlaceResult.OverlapNpc
    end
  end
  if self.RegisteredToys then
    local selfDetectRadius = self.PropsServerRadius or 0
    for toyActor, _ in pairs(self.RegisteredToys) do
      if toyActor and UE.UObject.IsValid(toyActor) then
        local serverDetectRadius = toyActor.ServerDetectRadius or 0
        if serverDetectRadius > 0 then
          local toyLocation = toyActor:K2_GetActorLocation()
          local totalRadius = selfDetectRadius + serverDetectRadius
          local manhattanDistance = math.abs(boxLocation.X - toyLocation.X) + math.abs(boxLocation.Y - toyLocation.Y) + math.abs(boxLocation.Z - toyLocation.Z)
          if manhattanDistance > totalRadius * 1.732 then
          else
            local euclidDistance = location:Dist(toyLocation)
            if totalRadius >= euclidDistance then
              if _G.GlobalConfig.bDebugSceneSeatEQS then
                UE4.UKismetSystemLibrary.DrawDebugString(_G.UE4Helper.GetCurrentWorld(), boxLocation, string.format("\231\142\169\229\133\183\229\141\160\228\189\141:%f + %f = %f", selfDetectRadius, serverDetectRadius, totalRadius), nil, UE4.FLinearColor(0.8, 0.5, 0.2, 0.8), drawTime)
                UE4.UKismetSystemLibrary.DrawDebugSphere(_G.UE4Helper.GetCurrentWorld(), toyLocation, totalRadius, 24, UE4.FLinearColor(0.8, 0.5, 0.2, 0.3), drawTime, 2)
              end
              return ToyPlaceResult.Blocked
            end
          end
        end
      end
    end
  end
  return ToyPlaceResult.Valid
end

function PlayerToyComponent:GetTipsType(validType)
  if not validType then
    return
  end
  return PlaceResultToTipsType[validType]
end

function PlayerToyComponent:OnZoneSceneCreateRoleplayPropRsp(Rsp)
  if 0 ~= Rsp.ret_info.ret_code then
    _G.NRCModuleManager:DoCmd(_G.TipsModuleCmd.TopHud_ShowTips, LuaText.put_prop_fail_a)
  else
    _G.NRCModuleManager:DoCmd(_G.TipsModuleCmd.TopHud_ShowTips, LuaText.put_prop_success)
  end
  _G.NRCModuleManager:DoCmd(_G.RolePlayModuleCmd.OnPutPropResponse, 0 == Rsp.ret_info.ret_code)
  self.PropID = nil
end

function PlayerToyComponent:OnPlayerRecycleRoleplayProp(PropID)
  local Request = _G.ProtoMessage:newZoneSceneRecycleRoleplayPropReq()
  Request.recycle_npc_id = PropID
  _G.ZoneServer:SendWithHandler(ProtoCMD.ZoneSvrCmd.ZONE_SCENE_RECYCLE_SCENE_SEAT_REQ, Request, self, self.OnZoneSceneRecycleRoleplayPropRsp)
end

function PlayerToyComponent:OnZoneSceneRecycleRoleplayPropRsp(Rsp)
  _G.NRCModuleManager:DoCmd(_G.RolePlayModuleCmd.OnRecyclePropResponse, 0 == Rsp.ret_info.ret_code)
end

function PlayerToyComponent:GetFreePlacingIsValid()
  return self.FreePlaceValidType == ToyPlaceResult.Valid
end

function PlayerToyComponent:SwitchCurrentPlacingProp(PropID)
  Log.Debug("PlayerToyComponent:SwitchCurrentPlacingProp", self.PropID, PropID)
  if self.PropID == PropID then
    return
  end
  if self.PreviewPropNpc then
    self.PreviewPropNpc:Destroy()
    self.PreviewPropNpc = nil
  end
  self.PropID = PropID
  self:BeginFreePlacing()
end

function PlayerToyComponent:AddPlacingPropRotation(delta)
  if not self.bInFreePlacing then
    return
  end
  if self.FreePlaceParams then
    if not self.FreePlaceParams.Yaw then
      self.FreePlaceParams.Yaw = 0
    end
    self.FreePlaceParams.Yaw = (self.FreePlaceParams.Yaw + delta) % 360
    if self.PreviewPropNpc then
      local rot = self.PreviewPropNpc:GetActorRotation()
      if rot then
        rot.Yaw = (rot.Yaw + delta) % 360
      end
      self.PreviewPropNpc:SetActorRotation(rot)
    end
  end
end

function PlayerToyComponent:ConfirmPlacingProp()
  if not self.bInFreePlacing then
    return
  end
  local bValid = self:GetFreePlacingIsValid()
  if bValid and self.PropID then
    local createPoints = {}
    local location = self.PreviewPropNpc:GetActorLocation()
    local rotation = self.PreviewPropNpc:GetActorRotation()
    local point = ProtoMessage:newPoint()
    point.pos.x = math.round(location.X)
    point.pos.y = math.round(location.Y)
    point.pos.z = math.round(location.Z)
    point.dir.x = 0
    point.dir.y = 0
    point.dir.z = math.round(rotation.Yaw * 10)
    table.insert(createPoints, point)
    local Request = _G.ProtoMessage:newZoneSceneCreateRoleplayPropReq()
    Request.create_pts = createPoints
    Request.roleplay_prop_config_id = self.PropID
    _G.ZoneServer:SendWithHandler(ProtoCMD.ZoneSvrCmd.ZONE_SCENE_CREATE_ROLEPLAY_PROP_REQ, Request, self, self.OnZoneSceneCreateRoleplayPropRsp, nil, true)
    self:EndFreePlacing()
    return true
  else
    local tipsType = self:GetTipsType(self.FreePlaceValidType)
    Log.Debug("PlayerToyComponent:ConfirmPlacingProp: tipsType", tipsType, self.FreePlaceValidType)
    if tipsType == ToyPlaceTipsType.UnInited then
      _G.NRCModuleManager:DoCmd(_G.TipsModuleCmd.TopHud_ShowTips, LuaText.prop_load)
    elseif tipsType == ToyPlaceTipsType.LandInvalid then
      _G.NRCModuleManager:DoCmd(_G.TipsModuleCmd.TopHud_ShowTips, LuaText.put_prop_fail_b)
    elseif tipsType == ToyPlaceTipsType.NotPlaneness then
      _G.NRCModuleManager:DoCmd(_G.TipsModuleCmd.TopHud_ShowTips, LuaText.put_prop_fail_a)
    end
  end
end

function PlayerToyComponent:CancelPlacingProp()
  if not self.bInFreePlacing then
    return
  end
  self:EndFreePlacing()
end

function PlayerToyComponent:BeginFreePlacing()
  self.bInFreePlacing = true
  local conf = _G.DataConfigManager:GetRoleplayPropConf(self.PropID, true)
  if not conf then
    Log.Debug("PlayerToyComponent:BeginFreePlacing: roleplayPropConf is nil", self.PropID)
    return
  end
  self.PropsServerRadius = conf.prop_server_radius or 0
  if not self.FreePlaceParams then
    self.FreePlaceParams = {
      DrawDebugType = UE4.EDrawDebugTrace.None,
      TraceColor = nil,
      TraceHitColor = nil
    }
    if _G.GlobalConfig.bDebugSceneSeatEQS then
      self.FreePlaceParams.DrawDebugType = UE4.EDrawDebugTrace.ForDuration
      self.FreePlaceParams.TraceColor = UE4.FLinearColor(0.3, 1, 0.1, 1)
      self.FreePlaceParams.TraceHitColor = UE4.FLinearColor(0.9, 0.2, 0.2, 1)
    end
  end
  local Box = {}
  if conf.prop_eqs_box_custom and #conf.prop_eqs_box_custom > 0 then
    for i, v in ipairs(conf.prop_eqs_box_custom) do
      table.insert(Box, tonumber(v))
    end
  else
    local ExportConf = _G.DataConfigManager:GetEqsBoxExport(self.PropID)
    if ExportConf and ExportConf.prop_eqs_box and #ExportConf.prop_eqs_box > 0 then
      for i, v in ipairs(ExportConf.prop_eqs_box) do
        table.insert(Box, tonumber(v))
      end
    end
  end
  if 3 ~= #Box then
    Log.Error("PlayerToyComponent:BeginFreePlacing Box is not 3", self.PropID)
    self.FreePlaceParams = nil
    return
  end
  self.FreePlaceParams.Offset = UE4.FVector(0, 0, Box[3] + (conf.lift_box or 0))
  self.FreePlaceParams.Extent = UE4.FVector(Box[1], Box[2], Box[3])
  self.FreePlaceParams.Tag = string.format("FreePlaceProp_%d", self.PropID)
  if conf.ray_distance then
    self.CreateDistance = conf.ray_distance
  end
  self.FreePlaceValidType = ToyPlaceResult.UnInited
  local location = self:GetPlacingPropPosition()
  self.PreviewPropNpc = _G.NRCModuleManager:DoCmd(_G.NPCModuleCmd.CreateLocalNPC, self.PropID, SceneUtils.ClientPos2ServerPos(location), 0, nil, PriorityEnum.Active_Player_Throw_Npc)
  if not self.PreviewPropNpc then
    Log.Debug("PlayerToyComponent:BeginFreePlacing CreateLocalNPC failed", self.PropID)
    return
  end
  local aiComp = self.PreviewPropNpc.AIComponent
  if aiComp then
    aiComp:ForceLockForReason(true, true, AIDefines.LockReason.TOY_FREE_PLACE)
  end
  self.PreviewPropNpc:SetHidden(true, NPCModuleEnum.NpcReasonFlags.ROLEPLAY_FREE_PLACE)
  self.PreviewPropNpc:SetCollisionDisable(true, NPCModuleEnum.NpcReasonFlags.ROLEPLAY_FREE_PLACE)
  self.PreviewPropNpc:AddEventListener(self, NPCModuleEvent.VIEW_LOADED, self.OnFreePlacingNpcLoaded)
end

function PlayerToyComponent:EndFreePlacing()
  self.bInFreePlacing = false
  self.PropID = nil
  self.PropsServerRadius = nil
  if self.PreviewPropNpc then
    self.PreviewPropNpc:Destroy()
  end
  self.PreviewPropNpc = nil
  self.FreePlaceValidType = nil
  self.FreePlaceParams = nil
end

function PlayerToyComponent:GetPlacingPropPosition()
  local playerPosition = self.owner:GetActorLocation()
  local cameraManager = self.owner:GetUEController().PlayerCameraManager
  local direction = cameraManager:GetCameraRotation():ToVector()
  direction.Z = 0
  direction = direction / direction:Size()
  local npcTargetOrigin = playerPosition + direction * self.CreateDistance
  local playerHeight = playerPosition.Z - self.owner:GetScaledHalfHeight()
  local landPos = SceneUtils.GetPosInLand(npcTargetOrigin, nil, nil, nil, self:GetAllPlayersCharacter(), nil, nil, nil, nil, _G.GlobalConfig.bDebugSceneSeatEQS)
  if not landPos then
    npcTargetOrigin.Z = playerHeight
    return npcTargetOrigin, true
  end
  local heightDelta = math.abs(playerHeight - landPos.Z)
  if heightDelta > self.HeightOffsetAllowance then
    npcTargetOrigin.Z = playerHeight
    return npcTargetOrigin, true
  end
  return landPos
end

function PlayerToyComponent:OnFreePlacingNpcLoaded(viewObj)
  if not self.PreviewPropNpc then
    return
  end
  self.PreviewPropNpc:RemoveEventListener(self, NPCModuleEvent.VIEW_LOADED, self.OnFreePlacingNpcLoaded)
  self.FreePlaceParams.Yaw = 0
  local bHeightDiffTooMuch = self:UpdatePreviewPropNpcTransform()
  if bHeightDiffTooMuch then
    self.FreePlaceValidType = ToyPlaceResult.HeightDiffTooMuch
  else
    self:UpdatePreviewPropNpcValidType()
  end
  self.owner:SendEvent(PlayerModuleEvent.ON_FREE_PLACE_PROP_VALID_CHANGED, self:GetFreePlacingIsValid(), self.FreePlaceValidType == ToyPlaceResult.UnInited)
  self:UpdatePlacingPropAppearance()
  self.PreviewPropNpc:SetHidden(false, NPCModuleEnum.NpcReasonFlags.ROLEPLAY_FREE_PLACE)
end

function PlayerToyComponent:UpdatePreviewPropNpcTransform()
  local targetPos, bHeightDiffTooMuch = self:GetPlacingPropPosition()
  self.PreviewPropNpc:SetActorLocation(targetPos)
  local playerLocation = self.owner:GetActorLocation()
  local npcLocation = self.PreviewPropNpc:GetActorLocation()
  local direction = playerLocation - npcLocation
  direction:Normalize()
  local rotator = UE.UKismetMathLibrary.MakeRotFromX(direction)
  local npcRot = UE.FRotator(0, (rotator.Yaw - 90 + 360 + (self.FreePlaceParams.Yaw or 0)) % 3600, 0)
  self.PreviewPropNpc:SetActorRotation(npcRot)
  return bHeightDiffTooMuch
end

function PlayerToyComponent:UpdatePreviewPropNpc(deltaTime)
  if not self.bInFreePlacing then
    return
  end
  if self.FreePlaceValidType == ToyPlaceResult.UnInited then
    return
  end
  if not self.FreePlaceParams then
    return
  end
  if not self.PreviewPropNpc then
    return
  end
  if not self.PreviewPropNpc.viewObj then
    return
  end
  local bHeightDiffTooMuch = self:UpdatePreviewPropNpcTransform()
  local bValidBefore = self:GetFreePlacingIsValid()
  if bHeightDiffTooMuch then
    self.FreePlaceValidType = ToyPlaceResult.HeightDiffTooMuch
  else
    self:UpdatePreviewPropNpcValidType(deltaTime)
  end
  local bValidAfter = self:GetFreePlacingIsValid()
  if bValidBefore ~= bValidAfter then
    self:UpdatePlacingPropAppearance()
    self.owner:SendEvent(PlayerModuleEvent.ON_FREE_PLACE_PROP_VALID_CHANGED, bValidAfter)
  end
end

function PlayerToyComponent:UpdatePreviewPropNpcValidType(deltaTime)
  local PlayerAbsoluteLocation = self.owner:GetActorLocation()
  local PlayerLocation = SceneUtils.ConvertAbsoluteToRelative(PlayerAbsoluteLocation)
  self.QueryParams.ActorsToIgnore = self:GetAllPlayersCharacter()
  deltaTime = deltaTime or 0.1
  local npcLocation = self.PreviewPropNpc.viewObj:K2_GetActorLocation()
  local boxLocation = npcLocation + self.FreePlaceParams.Offset
  local absoluteLocation = SceneUtils.ConvertRelativeToAbsolute(boxLocation)
  local newFreePlaceValidType = self:GetLocationPlaceResult(npcLocation, boxLocation, absoluteLocation, PlayerLocation, self.FreePlaceParams.Extent, self.PreviewPropNpc:GetActorRotation(), self.FreePlaceParams.Tag, self.FreePlaceParams.DrawDebugType, self.FreePlaceParams.TraceColor, self.FreePlaceParams.TraceHitColor, deltaTime)
  self.FreePlaceValidType = newFreePlaceValidType
end

function PlayerToyComponent:UpdatePlacingPropAppearance()
  if not self.bInFreePlacing then
    return
  end
  if not self.PreviewPropNpc then
    return
  end
  local viewObj = self.PreviewPropNpc:GetViewObject()
  if not viewObj then
    return
  end
  local bValid = self.FreePlaceValidType == ToyPlaceResult.Valid
  local assetKey = bValid and FreePlacingMatAssetKeyValid or FreePlacingMatAssetKeyInvalid
  local material = _G.NRCBigWorldPreloader:Get(assetKey)
  if not UE4.UObject.IsValid(material) then
    Log.Debug("PlayerToyComponent:UpdatePlacingPropAppearance: material is not valid", bValid, assetKey)
    return
  end
  local meshComps = viewObj:K2_GetComponentsByClass(UE4.UMeshComponent)
  if meshComps then
    for _, comp in tpairs(meshComps) do
      if comp.SetMaterial then
        local materialNum = comp:GetNumMaterials()
        for matIdx = 0, materialNum - 1 do
          comp:SetMaterial(matIdx, material)
        end
      end
    end
  end
end

function PlayerToyComponent:GetAllPlayersCharacter()
  local AllPlayer = _G.NRCModuleManager:DoCmd(_G.PlayerModuleCmd.GET_ALL_PLAYER)
  local IgnoreActor = {}
  for i, v in ipairs(AllPlayer) do
    table.insert(IgnoreActor, v.viewObj)
  end
  return IgnoreActor
end

function PlayerToyComponent:PlayerSitToSceneSeat(SeatNpc, SeatSlot, SpecialG6, SeatPointConf, FadeType)
  local NpcView = SeatNpc:GetViewObject()
  if not NpcView then
    Log.Error("PlayerSitToSceneSeat: NpcView is nil")
    return
  end
  local Player = self.owner
  if not Player then
    Log.Error("PlayerSitToSceneSeat: Player is nil")
    return
  end
  local Position, Direction, FloorHeight
  if not SeatSlot then
    if not SeatPointConf then
      Log.Error("PlayerSitToSceneSeat: Both SeatSlot and SeatPointConf are empty")
      return
    end
    local OffsetStr = SeatPointConf.seat_point_offset or "0;0;0"
    local OffsetParts = string.Split(OffsetStr, ";")
    local OffsetX = tonumber(OffsetParts[1]) or 0
    local OffsetY = tonumber(OffsetParts[2]) or 0
    local OffsetZ = tonumber(OffsetParts[3]) or 0
    local NpcLocation = NpcView:GetActorLocation()
    local NpcRotation = NpcView:GetActorRotation()
    local OffsetVector = UE.FVector(OffsetX, OffsetY, OffsetZ)
    local RotatedOffset = NpcRotation:RotateVector(OffsetVector)
    Position = NpcLocation + RotatedOffset
    local RotateStr = SeatPointConf.seat_point_rotate or "0;0;0"
    local RotateParts = string.Split(RotateStr, ";")
    local RotatePitch = tonumber(RotateParts[1]) or 0
    local RotateYaw = tonumber(RotateParts[2]) or 0
    local RotateRoll = tonumber(RotateParts[3]) or 0
    if 0 ~= RotatePitch or 0 ~= RotateYaw or 0 ~= RotateRoll then
      local RotationQuat = UE.UKismetMathLibrary.ComposeRotators(NpcRotation:Rotator(), UE.FRotator(RotatePitch, RotateYaw, RotateRoll)):Quaternion()
      Direction = RotationQuat:GetForwardVector()
    else
      Direction = NpcRotation:GetForwardVector()
    end
    FloorHeight = OffsetZ
  else
    local StaticMesh = NpcView:GetComponentByClass(UE4.UStaticMeshComponent)
    if not StaticMesh then
      Log.Error("PlayerSitToSceneSeat: StaticMesh is nil")
      return
    end
    local Transform = StaticMesh:Abs_GetSocketTransform(SeatSlot)
    local LocalTransform = StaticMesh:Abs_GetSocketTransform(SeatSlot, UE4.ERelativeTransformSpace.RTS_Component)
    if not Transform then
      Log.Error("PlayerSitToSceneSeat: Transform is nil for SeatSlot: " .. tostring(SeatSlot))
      return
    end
    Position = Transform.Translation
    Direction = Transform.Rotation:GetForwardVector()
    FloorHeight = LocalTransform.Translation.Z * Transform.Scale3D.Z
    if SpecialG6 then
      FloorHeight = 45
    end
  end
  if Player.playerHomeInteractionComponent then
    if SpecialG6 then
      self.SeatSkill = RocoSkillProxy.Create(SpecialG6, Player.viewObj.RocoSkill, PriorityEnum.Active_Player_Action)
      self.SeatSkill:SetCaster(Player.viewObj)
      self.SeatSkill:SetTargets({NpcView})
      self.SeatSkill:RegisterEventCallback("IgnoreSetLocation", self, function()
        self.SeatSkill.IgnoreSetLocation = true
      end)
      self.SeatSkill:RegisterEventCallback("StartSit", self, function()
        if Player.playerHomeInteractionComponent then
          Player.playerHomeInteractionComponent:StartSit(Position, Direction, FloorHeight, SpecialG6, FadeType)
          Position.Z = Position.Z + Player:GetHalfHeight()
          if self.SeatSkill and not self.SeatSkill.IgnoreSetLocation then
            Player:SetActorLocation(Position)
          end
        end
      end)
      self.SeatSkill:PlaySkill()
    else
      Player.playerHomeInteractionComponent:StartSit(Position, Direction, FloorHeight, nil, FadeType)
    end
  end
end

function PlayerToyComponent:PlayerLeaveSceneSeat()
  if self.owner.playerHomeInteractionComponent then
    self.owner.playerHomeInteractionComponent:EndSit()
    if self.SeatSkill then
      local skill = self.SeatSkill
      self.SeatSkill = nil
      skill:CancelSkill()
      skill:Destroy()
      self.owner:StopAllMontage()
    end
  end
end

function PlayerToyComponent:PlayerInterruptSceneSeat(SeatView)
  if SeatView then
    SeatView:SetCollisionEnable(false)
  end
  if self.owner.playerHomeInteractionComponent then
    self.owner.playerHomeInteractionComponent:InterruptSit()
    if self.SeatSkill then
      local skill = self.SeatSkill
      self.SeatSkill = nil
      skill:CancelSkill()
      skill:Destroy()
      self.owner:StopAllMontage()
    end
  end
end

function PlayerToyComponent:PlayerFlashSkillForSceneSeat(NPCView, SpecialG6, CallBack)
  local SkillPath = SpecialG6 or "/Game/ArtRes/Effects/G6Skill/SceneEffect/Place/G6_Place_Chair_CharacterFliker.G6_Place_Chair_CharacterFliker"
  local Skill = RocoSkillProxy.Create(SkillPath, self.owner.viewObj.RocoSkill, PriorityEnum.Active_Player_Action)
  Skill:SetCaster(self.owner.viewObj)
  Skill:SetPassive(true)
  if NPCView then
    Skill:SetTargets({NPCView})
  end
  Skill:RegisterEventCallback("End", self, function(event, skill)
    self.owner:StopAllMontage()
    CallBack()
  end)
  Skill:PlaySkill(self, self.StopStartSeatSkill)
end

function PlayerToyComponent:StopStartSeatSkill()
  if self.SeatSkill then
    local skill = self.SeatSkill
    self.SeatSkill = nil
    skill:CancelSkill()
    skill:Destroy()
  end
end

function PlayerToyComponent:PlayerFlashToPoint(Point)
  if not self.owner then
    return
  end
  if not Point then
    return
  end
  local transform = SceneUtils.ConvertPointToTransform(Point)
  if not transform then
    return
  end
  self.owner:SetActorLocation(transform.Translation)
  self.owner:SetActorRotation(transform.Rotation:ToRotator())
  if self.owner.ForceSendMoveReq then
    self.owner:ForceSendMoveReq()
  end
end

function PlayerToyComponent:DebugSceneSeatEQS(Result)
  if Result.AbsoluteResultLocations then
    local TotalPoints = Result.AbsoluteResultLocations:Num()
    for i = 1, TotalPoints do
      local Score = 1.0
      local Loc = Result.AbsoluteResultLocations:Get(i)
      local IsValid = Result.ItemSuccess:Get(i)
      local Desc = Result.FailedTestDescriptions:Get(i)
      local Color = IsValid and UE.FLinearColor(0, 1, 0, 0.5) or UE.FLinearColor(1, 0, 0, 0.3)
      Score = Result.Scores and Result.Scores:Get(i) or 1.0
      if "" ~= Desc then
        Score = Desc
      end
      UE.UKismetSystemLibrary.Abs_DrawDebugSphere(_G.UE4Helper.GetCurrentWorld(), UE4.FVector(Loc.X, Loc.Y, Loc.Z), 25, 12, Color, 50, 2)
      UE4.UKismetSystemLibrary.Abs_DrawDebugString(_G.UE4Helper.GetCurrentWorld(), Loc + UE4.FVector(50, 50, 0), Score, nil, UE4.FLinearColor(0, 0, 1, 1), 50)
    end
  end
end

function PlayerToyComponent:OnSeatNPCNotify(NPC, Action)
  local Player = self.owner
  if not Player then
    return
  end
  Log.Debug("===PlayerToyComponent=====OnSeatNPCNotify===========", Player.serverData.base.name, Action.seat_idx, Action.is_client_req_leave_seat)
  if Player.isLocal then
    local InteractionComponent = NPC.InteractionComponent
    if InteractionComponent then
      local AllOptions = InteractionComponent:GetAllOptions()
      for _, Option in pairs(AllOptions) do
        if Option.config.action.action_type == Action.action_type then
          local CurrentAction = Option.CurrentAction
          if CurrentAction then
            local PlayerModule = NRCModuleManager:GetModule("PlayerModule")
            if PlayerModule then
              PlayerModule:UnRegisterEvent(CurrentAction, PlayerModuleEvent.ON_INPUT_MOVE_NOTIFY)
            end
            CurrentAction:Finish(false)
          end
        end
      end
    end
  elseif (Action.action_type == Enum.ActionType.ACT_SIT or Action.action_type == Enum.ActionType.ACT_HOME_SIT_LIE) and NPC and NPC.serverData and NPC.serverData.base and NPC.serverData.base.actor_id then
    local localPlayer = _G.NRCModuleManager:DoCmd(_G.PlayerModuleCmd.GET_LOCAL_PLAYER)
    if localPlayer and localPlayer.serverData and localPlayer.serverData.avatar_interact and localPlayer.serverData.avatar_interact.sit_info and localPlayer.serverData.avatar_interact.sit_info.sit_npc_id and NPC.serverData.base.actor_id == localPlayer.serverData.avatar_interact.sit_info.sit_npc_id then
      localPlayer:OnInteractionLookAt(Player.viewObj, Action.is_client_req_leave_seat)
    end
  end
  if Action.action_type == Enum.ActionType.ACT_SIT then
    local SeatIdx = Action.seat_idx + 1
    if -1 == Action.seat_idx then
      local SitInfo = {}
      SitInfo.seat_idx = -1
      SitInfo.sit_npc_id = 0
      local SeatArray = {}
      local SeatInfo = {}
      if Player and Player.serverData and Player.serverData.avatar_interact then
        SeatInfo.seat_idx = Player.serverData.avatar_interact.sit_info.seat_idx
        SeatInfo.interact_avatar_id = 0
        SeatIdx = SeatInfo.seat_idx + 1
      end
      table.insert(SeatArray, SeatInfo)
      self:SaveSeatNPCServerData(Player, NPC, SitInfo, SeatArray)
      if Action.is_client_req_leave_seat then
        local Conf = _G.DataConfigManager:GetRoleplayPropConf(NPC.config.id)
        if not Conf then
          return
        end
        local SpecialG6 = Conf["special_end_" .. SeatIdx]
        if SpecialG6 then
          self:PlayerFlashSkillForSceneSeat(NPC.viewObj, SpecialG6, function()
            self:PlayerInterruptSceneSeat()
            self:PlayerFlashToPoint(Action.before_sit_point)
          end)
        else
          self:PlayerLeaveSceneSeat()
        end
      else
        self:PlayerInterruptSceneSeat()
      end
    else
      local SitInfo = {}
      SitInfo.seat_idx = Action.seat_idx
      SitInfo.sit_npc_id = NPC.serverData.base.actor_id
      local SeatArray = {}
      local SeatInfo = {}
      if Player and Player.serverData then
        SeatInfo.seat_idx = Action.seat_idx
        SeatInfo.interact_avatar_id = Player.serverData.base.actor_id
      end
      table.insert(SeatArray, SeatInfo)
      self:SaveSeatNPCServerData(Player, NPC, SitInfo, SeatArray)
      local Conf = _G.DataConfigManager:GetRoleplayPropConf(NPC.config.id)
      if not Conf then
        return
      end
      local SpecialG6 = Conf["special_start_" .. SeatIdx]
      local SeatSlot = string.format("Seat_%s", SeatIdx)
      self:PlayerSitToSceneSeat(NPC, SeatSlot, SpecialG6, nil, Conf.scene_sit_blur_type)
    end
  elseif Action.action_type == Enum.ActionType.ACT_HOME_SIT_LIE then
    local SeatConf = _G.DataConfigManager:GetSeatConf(NPC.config.id)
    if not SeatConf then
      return
    end
    if -1 == Action.seat_idx then
      if Action.is_client_req_leave_seat then
        local FurnitureID = NPC.FurnitureID
        if not FurnitureID then
          Log.Error("PlayerToyComponent=====OnSeatNPCNotify=======FurnitureID is nil====", Player.serverData.base.name)
          HomeUtils.PlayerInterruptSceneSeat(Player, SeatConf.is_home_lie)
        else
          local FurnitureView = _G.NRCModuleManager:DoCmd(_G.NPCModuleCmd.GetFurnitureView, FurnitureID)
          if not FurnitureView then
            Log.Error("PlayerToyComponent=====OnSeatNPCNotify=======FurnitureView is nil====", Player.serverData.base.name)
            HomeUtils.PlayerInterruptSceneSeat(Player, SeatConf.is_home_lie)
          else
            HomeUtils.PlayerLeaveHomeSeat(Player, FurnitureView, Action.leave_point_idx, SeatConf.is_home_lie)
          end
        end
      else
        HomeUtils.PlayerInterruptSceneSeat(Player, SeatConf.is_home_lie)
      end
      local SitInfo = {}
      SitInfo.seat_idx = -1
      SitInfo.sit_npc_id = 0
      local SeatArray = {}
      local SeatInfo = {}
      if Player and Player.serverData and Player.serverData.avatar_interact then
        SeatInfo.seat_idx = Player.serverData.avatar_interact.sit_info.seat_idx
        SeatInfo.interact_avatar_id = 0
      end
      table.insert(SeatArray, SeatInfo)
      self:SaveSeatNPCServerData(Player, NPC, SitInfo, SeatArray)
    else
      local FurnitureID = NPC.FurnitureID
      if not FurnitureID then
        return
      end
      local FurnitureView = _G.NRCModuleManager:DoCmd(_G.NPCModuleCmd.GetFurnitureView, FurnitureID)
      if not FurnitureView then
        return
      end
      local SitInfo = {}
      local SeatArray = {}
      local CurSeatIdx = -1
      if Player and Player.serverData and Player.serverData.avatar_interact then
        CurSeatIdx = Player.serverData.avatar_interact.sit_info.seat_idx
      end
      if -1 ~= CurSeatIdx then
        SitInfo.seat_idx = Action.seat_idx
        SitInfo.sit_npc_id = NPC.serverData.base.actor_id
        local SeatOne = {}
        local SeatTwo = {}
        if Player and Player.serverData then
          SeatOne.seat_idx = CurSeatIdx
          SeatOne.interact_avatar_id = 0
          SeatTwo.seat_idx = Action.seat_idx
          SeatTwo.interact_avatar_id = Player.serverData.base.actor_id
        end
        table.insert(SeatArray, SeatOne)
        table.insert(SeatArray, SeatTwo)
        HomeUtils.PlayerChangeHomeSeat(Player, FurnitureView, Action.seat_idx + 1)
      else
        SitInfo.seat_idx = Action.seat_idx
        SitInfo.sit_npc_id = NPC.serverData.base.actor_id
        local SeatInfo = {}
        if Player and Player.serverData then
          SeatInfo.seat_idx = Action.seat_idx
          SeatInfo.interact_avatar_id = Player.serverData.base.actor_id
        end
        table.insert(SeatArray, SeatInfo)
        HomeUtils.PlayerSitToHomeSeat(Player, FurnitureView, Action.seat_idx + 1, SeatConf.is_home_lie)
      end
      self:SaveSeatNPCServerData(Player, NPC, SitInfo, SeatArray)
    end
  end
end

function PlayerToyComponent:SaveSeatNPCServerData(Player, NPC, NewSitInfo, NewSeatInfo)
  if Player and Player and Player.serverData and Player.serverData.avatar_interact then
    Player.serverData.avatar_interact.sit_info = NewSitInfo
  end
  if NPC and NPC.serverData and NPC.serverData.npc_interact and NPC.serverData.npc_interact.seat_info then
    local SeatInfo = NPC.serverData.npc_interact.seat_info.seat_info
    for __, NewInfo in ipairs(NewSeatInfo) do
      for _, Info in pairs(SeatInfo) do
        if Info.seat_idx == NewInfo.seat_idx then
          Info.interact_avatar_id = NewInfo.interact_avatar_id
        end
      end
    end
  end
end

function PlayerToyComponent:SavePropNpcServerData(Player, NPC, NewPropNPCInfo, NewPropPlayerInfo)
  if Player and Player.serverData and Player.serverData.roleplay_prop_info then
    Player.serverData.roleplay_prop_info.entered_prop_info = NewPropPlayerInfo
  end
  if NPC and NPC.serverData and NPC.serverData.npc_prop then
    local PropNpcInfo = NPC.serverData.npc_prop.npc_prop_slot_infos
    for _, NewInfo in ipairs(NewPropNPCInfo) do
      for _, Info in ipairs(PropNpcInfo) do
        if Info.slot_idx == NewInfo.slot_idx then
          Info.holder_avatar_id = NewInfo.holder_avatar_id
        end
      end
    end
  end
end

function PlayerToyComponent:OnPlayerEnterBox()
  Log.Error("PlayerToyComponent:OnPlayerEnterBox")
  _G.NRCModuleManager:DoCmd(_G.FriendModuleCmd.OnCmdStartOverrideAttachment, self.owner.viewObj)
end

function PlayerToyComponent:OnPlayerLeaveBox()
  Log.Error("PlayerToyComponent:OnPlayerLeaveBox")
  _G.NRCModuleManager:DoCmd(_G.FriendModuleCmd.OnCmdStopOverrideAttachment, self.owner.viewObj)
end

function PlayerToyComponent:OnPlayerTeleportFinish()
  if _G.FunctionBanManager:GetConditionCounter(Enum.PlayerConditionType.PCT_PROP_BLINDBOX) then
    local Player = self.owner
    if Player then
      self:RevertPLayer()
    end
  end
end

function PlayerToyComponent:RevertPLayer()
  local Player = self.owner
  if Player then
    Player:SetVisible(true)
    Player:SetViewVisible(true)
    if Player.playerHomeInteractionComponent then
      Player.playerHomeInteractionComponent:SetCollisionEnable(true)
    end
    if Player and UE.UObject.IsValid(Player.viewObj) then
      Player.viewObj:SetActorScale3D(_G.FVectorOne)
      Player.viewObj:SetHiddenMask(false, UE4.EPlayerForceHiddenType.BlindBox)
    end
    _G.FunctionBanManager:RemovePlayerConditionType(Enum.PlayerConditionType.PCT_PROP_BLINDBOX)
    self:OnPlayerLeaveBox()
  end
end

function PlayerToyComponent:PlayJumpBoxAnim(OutPlayer, NPC, Caller, OnSkillFinished)
  local NpcView = NPC.viewObj
  local Player = self.owner
  if not NpcView or not Player then
    return
  end
  if not OutPlayer then
    Log.Error("====PlayerToyComponent:PlayJumpBoxAnim===OutPlayer is nil==")
    return
  end
  local Conf = _G.DataConfigManager:GetRoleplayPropConf(NPC.config.id)
  if not Conf then
    return
  end
  local SkillPath = Conf.blindbox_battle_pos or "/Game/ArtRes/Effects/G6Skill/SceneEffect/G6_WanJu_XiaRenXiang_Out_Quick.G6_WanJu_XiaRenXiang_Out_Quick"
  local Skill = RocoSkillProxy.Create(SkillPath, NpcView.RocoSkill, PriorityEnum.Active_Player_Action)
  if not Skill then
    return
  end
  if OutPlayer.inputComponent then
    OutPlayer.inputComponent:SetInputEnable(self, true, "NPCActionBattleWatchLite")
  end
  Skill:SetCaster(Player.viewObj)
  Skill:SetTargets({NpcView})
  local Characters = {}
  Characters[UE4.EBattleStaticActorType.Player_2] = OutPlayer.viewObj
  Skill:SetCharacters(Characters)
  Skill:RegisterEventCallback("End", self, function()
    self:RevertPLayer()
    NPC:SetVisible(false)
    NPC:SetNotDestroyFlag(false)
    if Caller and OnSkillFinished then
      Caller:OnSkillFinished()
    end
  end)
  Skill:PlaySkill(self, function()
    if Player and UE.UObject.IsValid(Player.viewObj) then
      Player.viewObj:SetHiddenMask(false, UE4.EPlayerForceHiddenType.BlindBox)
    end
  end)
  NPC.InteractionComponent:TryDisableInteraction()
  NPC:SetNotDestroyFlag(true)
end

function PlayerToyComponent:RegisterToy(toyActor)
  if not toyActor or not UE.UObject.IsValid(toyActor) then
    return false
  end
  if self.RegisteredToys[toyActor] then
    Log.Debug("PlayerToyComponent:RegisterToy", "Toy already registered", self, toyActor)
    return true
  end
  self.RegisteredToys[toyActor] = true
  Log.Debug("PlayerToyComponent:RegisterToy", "Toy registered successfully", self, toyActor)
  return true
end

function PlayerToyComponent:UnregisterToy(toyActor)
  if not toyActor or not UE.UObject.IsValid(toyActor) then
    return false
  end
  if not self.RegisteredToys[toyActor] then
    Log.Debug("PlayerToyComponent:UnregisterToy", "Toy not found in registered list", self, toyActor)
    return false
  end
  self.RegisteredToys[toyActor] = nil
  Log.Debug("PlayerToyComponent:UnregisterToy", "Toy unregistered successfully", self, toyActor)
  return true
end

return PlayerToyComponent

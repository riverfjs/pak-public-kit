local Base = require("NewRoco.Modules.Core.Scene.Component.Ability.AbilityBase")
local StatType = require("NewRoco.Modules.Core.Scene.Component.Stat.StatType")
local PlayerModuleEvent = require("NewRoco.Modules.Core.PlayerModule.PlayerModuleEvent")
local SummonPetComponent = require("NewRoco.Modules.Core.Scene.Component.Interaction.SummonPetComponent")
local SceneUtils = require("NewRoco.Modules.Core.Scene.Common.SceneUtils")
local AbilityID = require("NewRoco.Modules.Core.Scene.Component.Ability.AbilityID")
local OffRideAllAbility = Base:Extend("OffRideAllAbility")

function OffRideAllAbility:Init(abilityConf)
  Base.Init(self, abilityConf)
end

function OffRideAllAbility:Start(onFinished, needReCall, ManualOff)
  Log.Debug("OffRideAllAbility Start")
  Base.Start(self, onFinished)
  if self.caster.buffComponent:HasBuff("Transform_Buff") then
    return
  end
  if self.caster and self.caster.InviteComponent then
    self.caster.InviteComponent:InteractCancel()
  end
  local rideComponent = self.caster.viewObj.BP_RideComponent
  if rideComponent.bIsDoubleRide2p then
    self:OffRide2p()
    return
  end
  if UE.UObject.IsValid(rideComponent.RidePet) and rideComponent.RidePet.Mesh:GetAnimInstance().bIsInDoubleRide and rideComponent.double_ride_2p_id then
    local player_2p = _G.NRCModuleManager:DoCmd(_G.PlayerModuleCmd.GetPlayerByServerID, rideComponent.double_ride_2p_id)
    if player_2p and player_2p.viewObj.BP_RideComponent.bIsDoubleRide2p then
      Log.Debug("OffRideAllAbility remove 2p while 1p remove")
      player_2p.statusComponent:RemoveStatus(ProtoEnum.WorldPlayerStatusType.WPST_RIDEALL, ProtoEnum.WPST_OpCode.WPST_OPCODE_REMOVE)
    end
  end
  rideComponent.double_ride_2p_id = nil
  if self.caster.isLocal then
    self.caster:SendEvent(PlayerModuleEvent.ON_DOUBLERIDE_SUCCEED, false, false)
  end
  local scenePet = rideComponent.ScenePet
  local petGid
  if scenePet then
    petGid = scenePet.gid
  end
  if self.caster.statusComponent:HasStatus(Enum.WorldPlayerStatusType.WPST_AIMTHROWING) then
    self.caster.statusComponent:RemoveStatus(Enum.WorldPlayerStatusType.WPST_AIMTHROWING)
  else
    self.caster.abilityComponent:StopAbility(true, AbilityID.END_THROW)
  end
  rideComponent:StopRide(ManualOff)
  self._buffName = "RideAll_Buff"
  if self.caster.buffComponent:HasBuff(self._buffName) then
    self.caster.buffComponent:RemoveBuff(self._buffName)
  end
  if needReCall and type(needReCall) ~= "table" and petGid then
    local player = self.caster
    if player and player.isLocal then
      local Comp = player:EnsureComponent(SummonPetComponent)
      Comp:SummonWithGID(petGid)
    end
  end
  if self.caster.isLocal then
    NRCModuleManager:DoCmd(PlayerModuleCmd.MarkSendMoveReq)
  end
end

function OffRideAllAbility:Interrupt()
  Log.Error("\232\167\163\230\149\163\233\170\145\228\185\152\232\162\171\230\137\147\230\150\173\239\188\140\228\187\141\231\132\182\231\187\167\231\187\173\232\167\163\230\149\163")
  self:Start()
end

function OffRideAllAbility:Recover(owner)
  self:Start()
end

function OffRideAllAbility:OffRide2p()
  Log.Debug("OffRideAllAbility OffRide2p")
  local rideComponent = self.caster.viewObj.BP_RideComponent
  local player_1p = rideComponent.RidePet.Rider.sceneCharacter
  rideComponent.bIsDoubleRide2p = false
  rideComponent:StopDoubleRide2p()
  rideComponent:UpdateHeadWidgetDoubleRide(false)
  local customParams_1P = player_1p.statusComponent:GetCustomParams(ProtoEnum.WorldPlayerStatusType.WPST_RIDEALL)
  if customParams_1P and customParams_1P.ride_param and customParams_1P.ride_param.double_ride_2p_id ~= nil and customParams_1P.ride_param.double_ride_2p_id >= 0 then
    customParams_1P.ride_param.double_ride_2p_id = 0
    player_1p.statusComponent:RefreshStatus(ProtoEnum.WorldPlayerStatusType.WPST_RIDEALL, 1, ProtoEnum.WPST_OpCode.WPST_OPCODE_REFRESH, customParams_1P)
    if player_1p.isLocal then
      player_1p:SendEvent(PlayerModuleEvent.ON_STATUS_REFRESH, ProtoEnum.WorldPlayerStatusType.WPST_RIDEALL, 1, ProtoEnum.WPST_OpCode.WPST_OPCODE_REFRESH)
    end
  end
  player_1p:SendEvent(PlayerModuleEvent.ON_RIDEPET_CHANGE_MOVETYPE)
  self._buffName = "RideAll_Buff"
  if self.caster.buffComponent:HasBuff(self._buffName) then
    self.caster.buffComponent:RemoveBuff(self._buffName)
  end
  local VisitorPos, MoveMode = self:FindOff2PPos(player_1p, self.caster, 90)
  if VisitorPos then
    self.caster:SetActorLocation(VisitorPos)
  end
  if self.caster.isLocal then
    NRCModuleManager:DoCmd(PlayerModuleCmd.MarkSendMoveReq)
  else
    self.caster.viewObj.Mesh.bEabledAuxiliaryAnimGraphThread = true
  end
  MoveMode = UE4.EMovementMode.MOVE_Walking
  self.caster.viewObj.CharacterMovement:SetMovementMode(MoveMode)
  self.caster.viewObj.CharacterMovement:SetActive(true)
  if MoveMode == UE4.EMovementMode.MOVE_Swimming then
    self.caster.viewObj.EnvInfoComponent:ForceUpdateSurfaceImmediately()
    self.caster.viewObj.CharacterMovement:UpdateWaterDepth()
  end
  if player_1p.isLocal then
    player_1p:SendEvent(PlayerModuleEvent.ON_DOUBLERIDE_SUCCEED, false, true)
  end
  if self.caster.isLocal then
    self.caster:SendEvent(PlayerModuleEvent.ON_DOUBLERIDE_SUCCEED, false, false)
    local ABP = player_1p:GetAnimComponent():GetAnimInstance("RideAll")
    if ABP then
      ABP.bEnableTransformFilter = false
    end
  end
  self.caster:SendEvent(PlayerModuleEvent.ON_PLAYER_RIDING_ACTUALLY, false)
  local RideComp1P = player_1p.viewObj.BP_RideComponent
  RideComp1P:LuaDoubleRideStatusChange(player_1p.viewObj, self.caster.viewObj, false)
  RideComp1P.ScenePet:OnSetDoubleRide2P(false, self.caster)
end

function OffRideAllAbility:FindOff2PPos(player_1p, player_2p, useStartAngle)
  local player = player_1p
  local localplayer = NRCModuleManager:DoCmd(PlayerModuleCmd.GET_LOCAL_PLAYER)
  if player and localplayer then
    local SphereRadius = player.viewObj.CapsuleComponent:GetScaledCapsuleRadius()
    local BasePos = player.viewObj:Abs_K2_GetActorLocation()
    local RidePet = player.viewObj.BP_RideComponent.RidePet
    BasePos.Z = BasePos.Z + 45
    if RidePet.CharacterEnvInfo:GetImmergeWaterDepth() > 1 then
      local WaterZ = RidePet.CharacterEnvInfo:GetWaterSurfacePos().Z
      if WaterZ > BasePos.Z - 35 then
        BasePos.Z = WaterZ + 35
      end
    end
    local BaseForward = player.viewObj:GetActorForwardVector()
    local OnLineGlobalConfig = _G.DataConfigManager:GetTable(DataConfigManager.ConfigTableId.ONLINE_GLOBAL_CONFIG):GetAllDatas()
    local radiusKey = "online_visitor_bornpoint_location_radius"
    if player.viewObj.BP_RideComponent.RidePet then
      radiusKey = "online_rider_bornpoint_location_radius"
    end
    local radiusList
    for i = 1, #OnLineGlobalConfig do
      if OnLineGlobalConfig[i].key == radiusKey then
        radiusList = OnLineGlobalConfig[i].numList
        break
      end
    end
    local BaseRadius = radiusList[1]
    local tryRadiusTime = 3
    local radiusStep = (radiusList[2] - BaseRadius) / tryRadiusTime
    local tryTime = 8
    local HorizTraceChannel = UE4.UNRCStatics.ConvertToTraceChannel(UE4.ECollisionChannel.ECC_Camera)
    local AirWallTraceChannel = UE4.UNRCStatics.ConvertToTraceChannel(UE4.ECollisionChannel.ECC_GameTraceChannel14)
    local LandTraceChannel = UE4.UNRCStatics.ConvertToTraceChannel(UE4.ECollisionChannel.ECC_GameTraceChannel5)
    local WalkableZ = math.cos(math.rad(55))
    local DrawDebugType = UE.EDrawDebugTrace.None
    local ActorToIgnore = {
      player.viewObj,
      player.viewObj.BP_RideComponent.RidePet
    }
    if player_2p then
      table.insert(ActorToIgnore, player_2p.viewObj)
    end
    local tryPos = {}
    for r = 0, tryRadiusTime - 1 do
      local radius = BaseRadius + r * radiusStep
      local startAngle = math.rand(0, 360)
      if nil ~= useStartAngle then
        startAngle = useStartAngle
      end
      for i = 0, tryTime - 1 do
        local ForwardRotator = UE.UKismetMathLibrary.Conv_VectorToRotator(BaseForward)
        local traceDir = UE.UKismetMathLibrary.Conv_RotatorToVector(UE.FRotator(0, startAngle + i * 360 / tryTime + ForwardRotator.Yaw, 0))
        local traceEndLocation = BasePos + traceDir * radius
        local HitResult, bHit = UE.UKismetSystemLibrary.Abs_SphereTraceSingle(player.viewObj, BasePos, traceEndLocation, SphereRadius, HorizTraceChannel, false, ActorToIgnore, DrawDebugType, nil, true, UE.FLinearColor(0, 1, 0, 1), UE.FLinearColor(1, 0, 0, 1), 2)
        local AirHitResult, bAirHit = UE.UKismetSystemLibrary.Abs_SphereTraceSingle(player.viewObj, BasePos, traceEndLocation, SphereRadius, AirWallTraceChannel, false, ActorToIgnore, DrawDebugType, nil, true, UE.FLinearColor(0, 1, 0, 1), UE.FLinearColor(1, 0, 0, 1), 2)
        if not bHit and not bAirHit then
          table.insert(tryPos, traceEndLocation)
          HitResult, bHit = UE.UKismetSystemLibrary.Abs_SphereTraceSingle(player.viewObj, traceEndLocation, traceEndLocation - UE.FVector(0, 0, 400), SphereRadius + 3, LandTraceChannel, false, nil, DrawDebugType, nil, true, UE.FLinearColor(0, 1, 0, 1), UE.FLinearColor(1, 0, 0, 1), 2)
          local OutSurface, OutWaterDepth, OutHit = UE.URocoMapUtils.GetSurface(player.viewObj, SceneUtils.ConvertAbsoluteToRelative(traceEndLocation), nil, nil, nil, UE.FVector(0, 0, -1))
          local resLoation
          if bHit and WalkableZ < HitResult.ImpactNormal.Z and OutWaterDepth < 110 then
            resLoation = HitResult.Location
            resLoation.Z = HitResult.ImpactPoint.Z + player.viewObj.CapsuleComponent:GetScaledCapsuleHalfHeight() + 5
            if localplayer.viewObj:CapsuleHasRoomCheck(player.viewObj.CapsuleComponent, resLoation, 0, 0, DrawDebugType) then
              return resLoation
            end
          end
          resLoation = SceneUtils.ConvertRelativeToAbsolute(OutHit.Location)
          if OutWaterDepth > 110 and traceEndLocation.Z - resLoation.Z < 400 then
            resLoation.Z = resLoation.Z - 37
            if localplayer.viewObj:CapsuleHasRoomCheck(player.viewObj.CapsuleComponent, resLoation, 0, 0, DrawDebugType) then
              return resLoation, UE4.EMovementMode.MOVE_Swimming
            end
          end
        end
      end
    end
    for _, fallingPos in ipairs(tryPos) do
      local resLoation = fallingPos
      resLoation.Z = resLoation.Z + 5
      if localplayer.viewObj:CapsuleHasRoomCheck(player.viewObj.CapsuleComponent, resLoation, 0, 0, DrawDebugType) then
        return resLoation
      end
    end
  end
  return nil
end

return OffRideAllAbility

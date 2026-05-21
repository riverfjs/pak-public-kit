require("UnLuaEx")
local PlayerModuleEvent = require("NewRoco.Modules.Core.PlayerModule.PlayerModuleEvent")
local AbilityHelperManager = require("NewRoco.Modules.Core.Scene.Component.Ability.AbilityHelperManager")
local AbilityID = require("NewRoco.Modules.Core.Scene.Component.Ability.AbilityID")
local ScenePlayerPet = require("NewRoco.Modules.Core.Scene.Actor.ScenePlayerPet")
local PetMutationUtils = require("NewRoco.Utils.PetMutationUtils")
local AbilityEvent = require("NewRoco.Modules.Core.Scene.Component.Ability.AbilityEvent")
local MagicReplayModuleEvent = require("NewRoco.Modules.System.MagicReplay.MagicReplayModuleEvent")
local BP_RideComponent_C = NRCClass()

function BP_RideComponent_C:ReceiveBeginPlay()
  self.Overridden.ReceiveBeginPlay(self)
  self:AddEventListener()
  self._abilityHelper = AbilityHelperManager.GetHelper(AbilityID.RIDE_ALL)
  self.AutoReClimb = false
  self.bIsDoubleRide2p = false
  self.MinCapsuleHalfHeight = 85
  self.MinCapsuleRadius = 34
  self.SocketType = -1
  UpdateManager:Register(self)
end

function BP_RideComponent_C:ReceiveEndPlay(EndPlayReason)
  self.Overridden.ReceiveEndPlay(self, EndPlayReason)
  if self.StopRideDelayID then
    _G.DelayManager:CancelDelayById(self.StopRideDelayID)
  end
  self:RemoveEventListener()
  UpdateManager:UnRegister(self)
end

function BP_RideComponent_C:ChangeMoveType(RideMoveType, RideMovementId)
  if RideMoveType ~= self.RideMoveType or RideMovementId ~= self.RideMovementId then
    self.RideMoveType = RideMoveType
    self.RideMovementId = RideMovementId
    self.Rider.sceneCharacter:SendEvent(PlayerModuleEvent.ON_RIDEPET_CHANGE_MOVETYPE)
  end
end

function BP_RideComponent_C:OnTick(DeltaSeconds)
  local RiderPlayerLua = self.Rider.sceneCharacter
  if nil == RiderPlayerLua then
    return
  end
  if not self._hasEventListener then
    self:AddEventListener()
  end
  local StatusComponent = RiderPlayerLua.statusComponent
  local BuffComponent = RiderPlayerLua.buffComponent
  if self.RidePet and not StatusComponent:HasStatus(ProtoEnum.WorldPlayerStatusType.WPST_RIDEALL) then
    if BuffComponent:HasBuff("Transform_Buff") then
      return
    end
    Log.Error("\229\188\130\229\184\184\230\131\133\229\134\181\239\188\129\233\170\145\228\185\152\231\138\182\230\128\129\229\183\178\232\167\163\233\153\164\228\189\134\233\170\145\228\185\152\229\185\182\230\156\170\232\167\163\230\149\163\239\188\140\229\188\186\232\161\140\232\167\163\230\149\163...")
    self:OnRideFailed()
    self:StopRide()
    if BuffComponent:HasBuff("RideAll_Buff") then
      BuffComponent:RemoveBuff("RideAll_Buff")
    end
    return
  end
  local buff = BuffComponent:GetBuff("RideAll_Buff")
  if buff and buff.UpdateAudio then
    buff:UpdateAudio(DeltaSeconds)
  end
  if buff then
    if not self.TickHUDTime then
      self.TickHUDTime = 0
    end
    self.TickHUDTime = self.TickHUDTime + DeltaSeconds
    if self.TickHUDTime > 2 then
      self.TickHUDTime = 999
    end
    if self.TickHUDTime > 0.5 then
      self:UpdateHeadWidgetDoubleRide(true)
    end
  else
    self.TickHUDTime = 0
  end
  if not RiderPlayerLua.isLocal then
    if UE.UObject.IsValid(self.RidePet) and UE.UObject.IsValid(self.RideMoveComp) and (self.RideMoveComp.MovementMode ~= UE.EMovementMode.MOVE_Custom or self.RideMoveComp.CustomMovementMode ~= UE.ERocoCustomMovementMode.MOVE_Gliding) and self.ScenePet and self:IsPetOnlyFly(self.ScenePet.config.id) then
      self.RideMoveComp:SetMovementMode(UE.EMovementMode.MOVE_Custom, UE.ERocoCustomMovementMode.MOVE_Gliding)
    end
    if buff and buff.OnUpdateByComponent and buff.waitDoubleRide then
      buff:OnUpdateByComponent(DeltaSeconds)
      return
    end
    return
  end
  if self.RidePet and self.RideMoveComp and self.ScenePet and self.ScenePet.config then
    if self.Rider.CharacterMovement.MovementMode ~= UE.EMovementMode.MOVE_None then
      self.Rider.CharacterMovement:SetMovementMode(UE.EMovementMode.MOVE_None)
      self.Rider:SetCharacterMovementTickEnabled(false, "BP_RideComponent")
    end
    local oldRideMoveType = self.RideMoveType
    local oldRideMovementId = self.RideMovementId
    self.RideMoveType, self.RideMovementId = self._abilityHelper:GetRideMoveType(RiderPlayerLua, self.ScenePet)
    if oldRideMoveType ~= self.RideMoveType or oldRideMovementId ~= self.RideMovementId then
      RiderPlayerLua:SendEvent(PlayerModuleEvent.ON_RIDEPET_CHANGE_MOVETYPE)
      if self.DelayStopRide and (self.RideMoveType == ProtoEnum.SceneRideAllType.SRAT_GROUND or self.RideMoveType == ProtoEnum.SceneRideAllType.SRAT_SWIM) then
        StatusComponent:RemoveStatus(ProtoEnum.WorldPlayerStatusType.WPST_RIDEALL)
        self.DelayStopRide = nil
      end
    end
    self:ShowDebugInfo(DeltaSeconds)
    if 0 == self.RideMoveType and self.RideMoveComp.MovementMode ~= UE.EMovementMode.MOVE_Falling then
      if BuffComponent:HasBuff("Transform_Buff") then
        StatusComponent:RemoveStatus(ProtoEnum.WorldPlayerStatusType.WPST_TRANSFORM)
      end
      self:OnRideFailed()
    end
    if self.RideMoveType == ProtoEnum.SceneRideAllType.SRAT_FLY and (self.RideMoveComp.MovementMode ~= UE.EMovementMode.MOVE_Custom or self.RideMoveComp.CustomMovementMode ~= UE.ERocoCustomMovementMode.MOVE_Gliding) then
      if self:IsPetOnlyFly(self.ScenePet.config.id) then
        if self:TryChangeToLink() then
          return
        end
        self:OnRideFailed()
        self.Rider.EnvInfoComponent:ForceUpdateSurfaceImmediately()
        self.Rider.CharacterMovement:UpdateWaterDepth()
        if self.Rider.CharacterMovement:GetImmergeWaterDepth() > 0 then
          self.Rider.MoveFXComponent:OnLandImpl(false, true)
        end
      else
        self.RideMoveComp:SetMovementMode(UE.EMovementMode.MOVE_Custom, UE.ERocoCustomMovementMode.MOVE_Gliding)
      end
    end
  end
  if buff and buff.OnUpdateByComponent then
    buff:OnUpdateByComponent(DeltaSeconds)
    return
  end
end

function BP_RideComponent_C:AddEventListener()
  local player = self:GetOwner().sceneCharacter
  if not self._hasEventListener and player then
    player:AddEventListener(self, PlayerModuleEvent.ON_OFF_RIDE_PET, self.OnVitalityOver)
    self._hasEventListener = true
  end
end

function BP_RideComponent_C:RemoveEventListener()
  local player = self:GetOwner().sceneCharacter
  if player then
    player:RemoveEventListener(self, PlayerModuleEvent.ON_OFF_RIDE_PET, self.OnVitalityOver)
  end
end

function BP_RideComponent_C:BindScenePet(pet, RideMoveType, MovementId)
  self:AddEventListener()
  if self.ScenePet then
    self.ScenePet:SetViewObj()
  end
  self.ScenePet = pet
  self.RideMoveType = RideMoveType or ProtoEnum.SceneRideAllType.SRAT_GROUND
  self.RideMovementId = MovementId or 0
end

function BP_RideComponent_C:AfterBeginRide()
  if self.ScenePet and self.RidePet then
    if self.RidePet and self.RidePet.Mesh and self.RidePet.Mesh.SkeletalMesh then
      UE4.UNRCStatics.ForceUpdateStreamingAssets(self.RidePet.Mesh.SkeletalMesh, 30)
    end
    local player = self.Rider.sceneCharacter
    self:BindPetAttrs()
    self.RidePet.SocketType = self.SocketType
    self.ScenePet:SetViewObj(self.RidePet)
    self:SetSmrInfo()
    self:SetDiffMat()
    self:BindFxList()
    if not self.ScenePet or not self.RidePet then
      Log.Error("RideComponent have no scene pet after SetViewObj!!!")
      self:OnRideFailed()
      self:StopRide()
      return
    end
    NRCModuleManager:DoCmd(PlayerModuleCmd.AddDistanceFadeMesh, self.RidePet)
    self.Rider.CharacterMovement.Acceleration:Set(0, 0, 0)
    self.Rider.CharacterMovement:ConsumeInputVector()
    self.Rider.CharacterMovement:ConsumeInputVector()
    if player.isLocal then
      player.movementComponent:ClearMoveInput()
    end
    if self.Rider.CharacterMovement.bIsMantle then
      self.Rider.CharacterMovement:MantleEnd()
    end
    if player then
      player:GetAnimComponent():StopAllMontage(0)
    end
    self:UpdateDrawDebugFlag()
    self.RidePet:AddMoveIngore(self.Rider)
    self.RideMoveComp = self.RidePet.CharacterMovement
    UE4.UNRCStatics.SetActorOwner(self.RidePet, self.Rider)
    if not self:GetOwner().sceneCharacter.isLocal then
      self:GetOwner():SetNetRole(UE4.ENetRole.ROLE_Authority)
      self.RidePet:SetNetRole(UE4.ENetRole.ROLE_SimulatedProxy)
      self.RidePet.CharacterMovement.bForceClientNetMode = true
      self.RidePet.CharacterMovement.bReplicateMode = true
      self.RidePet.CharacterMovement.bNetworkSkipProxyPredictionOnNetUpdate = true
      self.RidePet.CharacterMovement.NetworkSmoothingMode = UE4.ENetworkSmoothingMode.Exponential
      self.RidePet.CharacterMovement.NetworkMaxSmoothUpdateDistance = 512
      self.RidePet.CharacterMovement.NetworkNoSmoothUpdateDistance = 780
      self.RidePet.CharacterMovement.NetworkSimulatedSmoothLocationTime = 0.2
      self.RidePet.CharacterMovement.NetworkSimulatedSmoothRotationTime = 0.1
      self.RidePet.bSimGravityDisable = true
      if self.RidePet.Mesh:GetAttachParent() ~= self.RidePet:K2_GetRootComponent() then
        Log.Debug("Mesh\230\178\161\230\156\137\230\140\130\232\131\182\229\155\138\228\189\147\228\184\138,\229\136\135\228\184\186Lerp\229\144\140\230\173\165")
        self.RidePet.CharacterMovement:SetReplicateMode(UE.EReplicateMovementMode.ERM_LERP)
      end
    end
    if player.isLocal then
      UE4.UNRCStatics.SetSixLightingChannels(self.RidePet, true, false, true, false, false, false, false)
    else
      UE4.UNRCStatics.SetSixLightingChannels(self.RidePet, true, false, true, false, true, false, false)
    end
    local eyeViewOffset = _G.NRCModuleManager:DoCmd(_G.PlayerModuleCmd.GetRidePetEyeViewOffset, self.ScenePet.config.id, false)
    self.RidePet.EyesViewPointOffset = eyeViewOffset
    if self.RideMoveType == ProtoEnum.SceneRideAllType.SRAT_FLY then
      Log.Debug("\233\163\158\232\161\140\230\168\161\229\188\143")
      self.RideMoveComp:SetMovementMode(UE.EMovementMode.MOVE_Custom, UE.ERocoCustomMovementMode.MOVE_Gliding)
      if self:IsPetOnlyFly(self.ScenePet.config.id) then
        self.RideMoveComp.Velocity = FVectorZero
        local petLocation = self.RidePet:K2_GetActorLocation()
        local traceEnd = UE.UKismetMathLibrary.Add_VectorVector(petLocation, UE.FVector(0, 0, -500))
        local HitResult, bHit = UE.UKismetSystemLibrary.LineTraceSingle(self.RidePet, petLocation, traceEnd, UE4.ETraceTypeQuery.TraceTypeQuery5)
        if bHit then
          self.RideMoveComp:ApplyVelocity(UE.EApplyMovementStatType.ImpulseAdditive, UE.FVector(0, 0, self.RidePet.CharacterFlyMovement.HangStartSpeed))
        end
      end
    end
    if self.RideMoveType == ProtoEnum.SceneRideAllType.SRAT_CLIMB then
      Log.Debug("\230\148\128\231\136\172\230\168\161\229\188\143")
      self.RidePet.CharacterClimbMovement:TryClimbWhilePlayerClimb()
    end
    if self.RideMoveType == ProtoEnum.SceneRideAllType.SRAT_CLIMB_WATER then
      self.RidePet.CharacterClimbWaterFallMovement:TryClimbWaterWhilePlayerClimb()
    end
    if self.RideMoveType == ProtoEnum.SceneRideAllType.SRAT_SWIM then
      self.RidePet.CharacterEnvInfo:ForceUpdateSurfaceImmediately()
      self.RideMoveComp:SetMovementMode(UE.EMovementMode.MOVE_Swimming)
      if player.isLocal then
        player.abilityComponent:SendEvent(AbilityEvent.ON_ABILITY_CHANGED)
      end
    end
    if self.RideMoveComp.MovementMode == UE.EMovementMode.MOVE_None then
      self.RideMoveComp:SetMovementMode(UE.EMovementMode.MOVE_Walking)
    end
    if self.bForceFly then
      self.RidePet:K2_AddActorWorldOffset(UE.FVector(0, 0, 5000), false, nil, false)
      Log.Debug("\233\163\158\232\161\140\230\168\161\229\188\143")
      self.RideMoveComp:SetMovementMode(UE.EMovementMode.MOVE_Custom, UE.ERocoCustomMovementMode.MOVE_Gliding)
    end
    if player and player.FadeComponent then
      player.FadeComponent:SetFadeRange(150, 200)
    end
    player:SendEvent(PlayerModuleEvent.ON_RIDE_SET_VIEWOBJ_END, self.ScenePet)
    if not self.RidePet then
      Log.Error("[BP_RideComponent] RidePet nil in AfterBeginRide pet = ", self.ScenePet and self.ScenePet.config.name or "nil")
      self:OnRideFailed()
      self:StopRide()
      return
    end
    self.PetRadius = self.RidePet.CapsuleComponent:GetScaledCapsuleRadius()
    if self.ScenePet.config.id == 3412 then
      self.RidePet.RocoMoveFx:RemoveFxPlayer(UE.EMovementMode.MOVE_Swimming)
    end
    local buff = player.buffComponent:GetBuff("RideAll_Buff")
    if player.isLocal then
      NRCModuleManager:DoCmd(PlayerModuleCmd.MarkSendMoveReq)
      if buff then
        buff:ApplyTalent()
        buff:ApplyPropertyModifySpeed()
      end
    elseif buff then
      buff:SetPetMovementModeByMoveType()
    end
    if self.SocketType ~= ProtoEnum.ScenePlayerRideSocketType.H0 and self.SocketType ~= ProtoEnum.ScenePlayerRideSocketType.H1 and self.SocketType ~= ProtoEnum.ScenePlayerRideSocketType.H2 then
      self.Rider.RideEyeHeight = _G.DataConfigManager:GetTakephotoGlobalConfig("takephoto_hand_camera_height").num
    end
    local localCustomParams
    if player.isLocal then
      _G.NRCModuleManager:DoCmd(_G.MainUIModuleCmd.CloseCompass)
      local Id = ProtoEnum.WorldPlayerStatusType.WPST_RIDEALL
      local customParams = player.statusComponent._statusParams[Id]
      customParams = customParams or ProtoMessage:newPlayerStatusCustomParams()
      if customParams.ride_param == nil then
        customParams.ride_param = {}
      end
      customParams.ride_param.ride_load_finish = true
      localCustomParams = customParams
      player.statusComponent:RefreshStatus(ProtoEnum.WorldPlayerStatusType.WPST_RIDEALL, 1, ProtoEnum.WPST_OpCode.WPST_OPCODE_REFRESH, customParams)
      local Controller = self.Rider.sceneCharacter:GetUEController()
      if Controller then
        Controller:ChangeRocoCameraFadeRange(0, 300)
        local CameraAnimIns = Controller.PlayerCameraManager:GetCameraAnimInstance()
        if CameraAnimIns then
          local x, y, z = NRCModuleManager:DoCmd(PlayerModuleCmd.GetRideThrowCameraOffset, self.ScenePet.config.id)
          if 0 ~= x then
            CameraAnimIns.RideThrowCameraOffsetX = x
          end
          if 0 ~= y then
            CameraAnimIns.RideThrowCameraOffsetY = y
          end
          if 0 ~= z then
            CameraAnimIns.RideThrowCameraOffsetZ = z
          end
        end
      end
    end
    if not self.Rider:GetForceHidden() and not self.Rider.bHidden and not not self.Rider.Mesh:IsVisible() then
      local skillComponent = self.Rider.RocoSkill
      local skillObj = skillComponent:FindOrAddSkillObj(self._rideUpFxClass)
      if not skillObj then
        Log.Error("AbilityBase try reload skill obj ", skillObj and "true" or "false")
      end
      if self.CurActiveSkill and UE.UObject.IsValid(self.CurActiveSkill) then
        skillComponent:CancelSkill(self.CurActiveSkill, UE4.ESkillActionResult.SkillActionResultInterrupted)
        self.CurActiveSkill = nil
      end
      if skillObj then
        skillObj:SetCaster(self.RidePet)
        skillObj:SetTargets({
          self.RidePet
        })
        skillObj:SetCharacters({
          [UE.EBattleStaticActorType.Pet_1_1] = self.RidePet
        })
        skillObj:SetPassive(true)
        skillComponent:PlaySkill(skillObj)
        self.CurActiveSkill = skillObj
      end
    end
    if self.LuaRideStatusChange then
      self:LuaRideStatusChange(true)
    end
    player:SendEvent(PlayerModuleEvent.ON_PLAYER_RIDING_ACTUALLY, true)
    self.ScenePet:OnRideSuccess()
    _G.NRCEventCenter:DispatchEvent(_G.NRCGlobalEvent.ON_RIDE_PET_CREATED, self.Rider, self.RidePet)
    if self.Rider.sceneCharacter and self.Rider.sceneCharacter.IsMagicReplayActor and self.Rider.sceneCharacter:IsMagicReplayActor() then
      if buff.isRecoverRide then
        _G.NRCEventCenter:DispatchEvent(MagicReplayModuleEvent.OnMagicSeqNpcSpawned, self.RidePet)
      else
        _G.NRCEventCenter:DispatchEvent(MagicReplayModuleEvent.OnMagicSeqNpcSpawned, self.RidePet, true)
      end
    end
    if localCustomParams and localCustomParams.ride_param and localCustomParams.ride_param.double_ride_2p_id and localCustomParams.ride_param.double_ride_2p_id > 0 then
      local player2P = _G.NRCModuleManager:DoCmd(_G.PlayerModuleCmd.GetPlayerByServerID, localCustomParams.ride_param.double_ride_2p_id)
      if player2P then
        local buff2P = player2P.buffComponent:GetBuff("RideAll_Buff")
        if buff2P then
          buff2P:CheckEnterDoubleRide()
        end
      end
    end
    if self:IsInDoubleRide() then
    end
  else
    Log.Error("RideComponent have no scene pet!!!")
    self:OnRideFailed()
    self:StopRide()
  end
end

function BP_RideComponent_C:RefreshPose()
  self.Overridden.RefreshPose(self)
  if 1 == GlobalConfig.RideHudType then
    self:UpdateHeadWidget()
  else
    self:UpdateHeadWidgetDoubleRide(true)
  end
end

function BP_RideComponent_C:BindPetAttrs()
  local CharacterMovement = self.RidePet.CharacterMovement
  if self.bForceFly then
    CharacterMovement:RegisterCustomMoveMode(UE.ERocoCustomMovementMode.MOVE_Gliding)
  end
  local petID = self.ScenePet.config.id
  local RideConf = DataConfigManager:GetAllRidePet(petID)
  for _, MovementId in pairs(RideConf.basic_movement_list) do
    local MoveConfOrigin = DataConfigManager:GetRideBasicMovement(MovementId)
    local MoveConf = _G.BinDataUtils.BinDataUnboxing(MoveConfOrigin, false)
    local SubRideType = MoveConf.move_type
    if SubRideType > 5 then
      CharacterMovement:RegisterCustomMoveMode(SubRideType)
    end
    if self.bUseOriginParams or self.bForceFly then
    else
      local kvMode = false
      for k, v in pairs(MoveConf) do
        if type(k) == "string" and type(v) == "string" and k:match("^move_param_") then
          if kvMode or string.find(v, ":") then
            kvMode = true
          end
          if kvMode then
            local PropName, PropValue = string.match(v, "(.-):(.*)")
            if type(PropValue) == "string" and string.find(PropValue, "/") then
              local Folder, AssetName = string.match(v, "(.-)/(.*)")
              PropValue = "/Game/NewRoco/Modules/Core/Character/Rides/RideAll/RideCurve/" .. PropValue .. "." .. AssetName
            end
            self.RidePet.CharacterMovement:SetMovementParamByName(SubRideType, PropName, PropValue)
          end
        end
      end
      if kvMode then
      elseif SubRideType == ProtoEnum.SceneRideAllType.SRAT_GROUND then
        local MovementComp = self.RidePet.VehicleWalkMovement
        MovementComp.BaseMaxSpeed = MoveConf.move_param_1
        if MoveConf.move_param_2 then
          MovementComp.SlopeMaxSpeedCurve = LoadObject(MoveConf.move_param_2)
        end
        if MoveConf.move_param_3 then
          MovementComp.AccelerateCurve = LoadObject(MoveConf.move_param_3)
        end
        if MoveConf.move_param_4 then
          MovementComp.DeAccelerateCurve = LoadObject(MoveConf.move_param_4)
        end
        if MoveConf.move_param_5 then
          MovementComp.LinerAngularSpeedCurve = LoadObject(MoveConf.move_param_5)
        end
      elseif SubRideType == ProtoEnum.SceneRideAllType.SRAT_SWIM then
        local MovementComp = self.RidePet.CharacterSwimMovement
        MovementComp.BaseMaxSpeed = MoveConf.move_param_1
        MovementComp.StartSwimWaterDepth = MoveConf.move_param_2
        MovementComp.SwimJumpDownVelocityZ = MoveConf.move_param_6
        MovementComp.SwimLiftAccelerationZ = MoveConf.move_param_7
        MovementComp.SwimPosOffsetZ = MoveConf.move_param_8
        MovementComp.SwimPosOffsetZSpeedRatio = MoveConf.move_param_9
        MovementComp.SwimPosOffsetZMinAdjust = MoveConf.move_param_10
        MovementComp.MaxOutOfWaterStepHeight = MoveConf.move_param_11
        if MoveConf.move_param_3 then
          MovementComp.AccelerateCurve = LoadObject(MoveConf.move_param_3)
        end
        if MoveConf.move_param_4 then
          MovementComp.DeAccelerateCurve = LoadObject(MoveConf.move_param_4)
        end
        if MoveConf.move_param_5 then
          MovementComp.LinerAngularSpeedCurve = LoadObject(MoveConf.move_param_5)
        end
      elseif SubRideType == ProtoEnum.SceneRideAllType.SRAT_FLY then
        local MovementComp = self.RidePet.CharacterFlyMovement
        MovementComp.MaxAcc = MoveConf.move_param_1
        MovementComp.BaseMaxSpeed = MoveConf.move_param_2
        MovementComp.GravityRatio = MoveConf.move_param_5
        MovementComp.MaxFallingSpeed = MoveConf.move_param_6
        MovementComp.GlidingBreakingAcceleration = MoveConf.move_param_7
        MovementComp.GlidingFriction = MoveConf.move_param_8
        if MoveConf.move_param_3 then
          MovementComp.AngularSpeedLossRatioCurve = LoadObject(MoveConf.move_param_3)
        end
        if MoveConf.move_param_4 then
          MovementComp.LinerAngularSpeedCurve = LoadObject(MoveConf.move_param_4)
        end
      elseif SubRideType == ProtoEnum.SceneRideAllType.SRAT_CLIMB then
      end
    end
  end
  local climbMeshOffset = RideConf.climb_mesh_offset
  if climbMeshOffset then
    self.RidePet.CharacterClimbMovement:SetClimbMeshOffset(climbMeshOffset)
  end
  local StartSwimWaterDepth = RideConf.start_swim_water_depth
  if StartSwimWaterDepth and StartSwimWaterDepth > 0 then
    self.RidePet.CharacterSwimMovement.StartSwimImmergeDepth = StartSwimWaterDepth
  end
  local MaxStepHeight = RideConf.max_step_height
  if MaxStepHeight and MaxStepHeight > 0 then
    local Scale = self.RidePet:GetActorScale3D().X
    local PetCapsule = self.RidePet.CapsuleComponent
    self.RidePet.VehicleWalkMovement.MaxStepHeight = MaxStepHeight / 50 * Scale * PetCapsule:GetUnscaledCapsuleHalfHeight()
  end
  if RideConf.use_custom_camera then
    self.RidePet.bUseOverrideBaseCamera = true
    self.RidePet.OverrideBaseCameraX = -RideConf.custom_camera_x or 0
    self.RidePet.OverrideBaseCameraY = RideConf.custom_camera_y or 0
    self.RidePet.OverrideBaseCameraZ = RideConf.custom_camera_z or 0
  end
  if self.bUseOriginParams or self.bForceFly then
    return
  end
  if RideConf.second_active_skill__list then
    for _, ActiveSkillId in pairs(RideConf.second_active_skill__list) do
      local MoveConf = DataConfigManager:GetRideBasicMovement(ActiveSkillId)
      if MoveConf.active_type == ProtoEnum.SceneRideAllActiveType.SRAA_JUMP or MoveConf.active_type == ProtoEnum.SceneRideAllActiveType.SRAA_SWIMJUMP then
        local MovementComp = self.RidePet.CharacterFallingMovement
        MovementComp.MaxAcceleration = MoveConf.move_param_1
        MovementComp.BaseMaxSpeed = MoveConf.move_param_3
        MovementComp.LimitFallingSpeed = MoveConf.move_param_4
        break
      end
    end
  end
end

function BP_RideComponent_C:OnRideFailed()
  self.bIsLoading = false
  self.Rider.RideEyeHeight = 0
  self.SocketType = -1
  if self.bIsRoomFail and not self.bIsFastLoading then
    self.bIsRoomFail = false
    if self:TryChangeToLinkWhileRoomFail() then
      return
    end
  end
  local player = self.Rider.sceneCharacter
  if not player then
    Log.Error("RideComponent\230\137\190\228\184\141\229\136\176\229\175\185\229\186\148Lua Character")
    return
  end
  player.statusComponent:RemoveStatus(ProtoEnum.WorldPlayerStatusType.WPST_RIDEALL)
  if player.isLocal then
    player.statusComponent:OnMovementModeChange(nil, self.Rider.CharacterMovement.MovementMode, nil, self.Rider.CharacterMovement.CustomMovementMode)
  else
    self.Rider.Mesh.bEabledAuxiliaryAnimGraphThread = true
  end
  self.Rider.sceneCharacter:SendEvent(PlayerModuleEvent.ON_PLAYER_RIDING_FAILED)
end

function BP_RideComponent_C:StopRide(ManualStop)
  self.bIsRoomFail = false
  if self:GetOwner() and self:GetOwner().sceneCharacter then
    if not self:GetOwner().sceneCharacter.isLocal then
      self:GetOwner():SetNetRole(UE4.ENetRole.ROLE_SimulatedProxy)
      if self.RidePet then
        self.RidePet:SetNetRole(UE4.ENetRole.ROLE_Authority)
        self.RidePet.CharacterMovement.bForceClientNetMode = false
        self.RidePet.CharacterMovement.bReplicateMode = false
      end
      self.Rider.Mesh.bEabledAuxiliaryAnimGraphThread = true
    else
      local Controller = self.Rider.sceneCharacter:GetUEController()
      if Controller then
        Controller:ChangeRocoCameraFadeRange(100, 150)
      end
    end
  end
  self.DelayStopRide = nil
  local petRadius = 0
  local needReClimb = false
  self.RecoverPlayerMovemode = UE.EMovementMode.MOVE_Walking
  if self.RidePet then
    petRadius = self.RidePet.CapsuleComponent:GetScaledCapsuleRadius()
    if self.RideMoveType == ProtoEnum.SceneRideAllType.SRAT_CLIMB then
      needReClimb = true
      self.RecoverPlayerMovemode = UE.EMovementMode.MOVE_Falling
      self.RidePet.BP_RidePetRoleHpComponent:CheckFalling()
    elseif self.RideMoveType == ProtoEnum.SceneRideAllType.SRAT_SWIM then
      self.RecoverPlayerMovemode = UE.EMovementMode.MOVE_Swimming
    elseif self.RideMoveType ~= ProtoEnum.SceneRideAllType.SRAT_GROUND then
      if (nil == self.RideMoveComp or self.RideMoveComp.MovementMode == UE.EMovementMode.MOVE_Swimming) and self.RidePet.CharacterSwimMovement:GetImmergeWaterDepth() < 120 then
        self.RecoverPlayerMovemode = UE.EMovementMode.MOVE_Walking
      else
        self.RecoverPlayerMovemode = UE.EMovementMode.MOVE_Falling
      end
    end
  end
  if self.ScenePet then
    self.ScenePet:SetStatus(ProtoEnum.WorldPlayerPetStatusType.WPPST_IN_BAG)
    self.ScenePet:SetViewObj()
  end
  local actually_stop = false
  if self.ScenePet or self.RidePet then
    actually_stop = true
    self.curSessionId = nil
    if self.RidePet and UE.UObject.IsValid(self.RidePet) and self.Rider and UE.UObject.IsValid(self.Rider) and not self.Rider:GetForceHidden() and not self.Rider.bHidden and not not self.Rider.Mesh:IsVisible() then
      local skillComponent = self.Rider.RocoSkill
      local skillObj = skillComponent:FindOrAddSkillObj(self._rideDownFxClass)
      if not skillObj then
        Log.Error("AbilityBase try reload skill obj ", skillObj and "true" or "false")
      end
      if self.CurActiveSkill and UE.UObject.IsValid(self.CurActiveSkill) then
        skillComponent:CancelSkill(self.CurActiveSkill, UE4.ESkillActionResult.SkillActionResultInterrupted)
        self.CurActiveSkill = nil
      end
      if skillObj then
        self.StopRideDelayID = _G.DelayManager:DelayFrames(1, function(rideComp, skill)
          if not UE.UObject.IsValid(rideComp) then
            return
          end
          local Rider = rideComp.Rider
          if not (rideComp.CurActiveSkill == skill and UE.UObject.IsValid(Rider)) or not UE.UObject.IsValid(Rider.RocoSkill) then
            return
          end
          if Rider.LinkComponent.bIsLink then
            skill:SetTargets({
              Rider.LinkComponent.LinkAnchor
            })
          end
          Rider.RocoSkill:PlaySkill(skill)
        end, self, skillObj)
        skillObj:SetCaster(self.Rider)
        skillObj:SetTargets({
          self.Rider
        })
        skillObj:SetPassive(true)
        self.CurActiveSkill = skillObj
      end
    end
  end
  self.Overridden.StopRide(self)
  self.ScenePet = nil
  self.RideMoveType = nil
  self.SocketType = -1
  self.TickHUDTime = 0
  if 1 == GlobalConfig.RideHudType then
    self:UpdateHeadWidget()
  else
    self:UpdateHeadWidgetDoubleRide(false)
  end
  if self.Rider.sceneCharacter and self.Rider.sceneCharacter.FadeComponent then
    self.Rider.sceneCharacter.FadeComponent:SetFadeRange(100, 150)
  end
  if needReClimb or self.AutoReClimb then
    Log.Debug("BP_RideComponent_C \231\142\169\229\174\182\229\176\157\232\175\149\232\135\170\229\138\168\232\191\155\229\133\165\230\148\128\231\136\172")
    self.Rider.CharacterMovement:TryClimbWhileOffClimbPet(petRadius)
  end
  if actually_stop then
    if self.LuaRideStatusChange then
      self:LuaRideStatusChange(false)
    end
    self.Rider.sceneCharacter:SendEvent(PlayerModuleEvent.ON_PLAYER_RIDING_ACTUALLY, false)
  end
  self.RecoverPlayerMovemode = UE.EMovementMode.MOVE_None
  self.AutoReClimb = false
  self.bIsDoubleRide2p = false
  self.bIsLoading = false
  self.Rider.RideEyeHeight = 0
end

function BP_RideComponent_C:GetRideSocketAndType(Mesh, TryUseLocalForceSocket)
  if not (self.Rider and Mesh and self.ScenePet) or not self.ScenePet.config then
    return false
  end
  local TipsText = "pet_eco_reject"
  if self.Rider.sceneCharacter.statusComponent:HasStatus(ProtoEnum.WorldPlayerStatusType.WPST_TRANSFORM) then
    TipsText = "transform_failed"
  end
  if self.Rider.sceneCharacter.isLocal then
    local traceChannelAir = UE.ETraceTypeQuery.AirWall
    local airStartPos = self.Rider:Abs_K2_GetActorLocation()
    local airEndPos = self.Rider:Abs_K2_GetActorLocation() + UE.FVector(0, 0, -1)
    local hitAirResult, isAirHit = UE4.UKismetSystemLibrary.Abs_SphereTraceSingle(self.Rider, airStartPos, airEndPos, 200, traceChannelAir, false)
    if isAirHit or hitAirResult.bStartPenetrating then
      _G.NRCModeManager:DoCmd(TipsModuleCmd.TopHud_ShowTips, _G.LuaText[TipsText])
      Log.Warning("\229\156\168\231\169\186\230\176\148\229\162\153\233\153\132\232\191\145\233\170\145\228\185\152")
      return false
    end
  end
  local petID = self.ScenePet.config.id
  local ForceConf = DataConfigManager:GetRideSocket(petID, true)
  local ForceSocket
  self.SocketName_Male = "S2"
  if 1 == self.Rider.sceneCharacter.gender then
    self.SocketName_Male = "S1"
  end
  if ForceConf then
    if 1 == self.Rider.sceneCharacter.gender then
      ForceSocket = ForceConf.force_socket_pc1
    else
      ForceSocket = ForceConf.force_socket_pc2
    end
  end
  if self.ScenePet and "" ~= ForceSocket and nil ~= ForceSocket then
    local gender, slot_type, suffix = string.match(ForceSocket, "^(.-)_(.-)_Ride(.*)$")
    if Mesh:FindSocket(ForceSocket) then
      for SocketNameFormList, v in pairs(Enum.ScenePlayerRideSocketType) do
        if SocketNameFormList == slot_type then
          self.SocketName_Male = gender
          self.RideSocketName = ForceSocket
          self.SocketType = v
          self.SocketName_Head = slot_type
          self.SocketName_Tail = suffix
          return true
        end
      end
    end
  end
  for SocketName_Head, v in pairs(Enum.ScenePlayerRideSocketType) do
    local SocketName = string.format("%s_%s_Ride", self.SocketName_Male, SocketName_Head)
    if Mesh:FindSocket(SocketName) then
      self.RideSocketName = SocketName
      self.SocketType = v
      self.SocketName_Head = SocketName_Head
      self.SocketName_Tail = ""
      return true
    end
  end
  return false
end

function BP_RideComponent_C:SetRelativeTransform()
  if not self.ScenePet then
    return false
  end
  if not self.Rider.sceneCharacter then
    Log.Error("\233\170\145\228\185\152\229\143\172\229\148\164\230\151\182\239\188\140\232\167\146\232\137\178\232\186\171\228\184\138\230\178\161\230\156\137sceneCharacter")
    return false
  end
  local PetID = self.ScenePet.config.id
  local PetConf = DataConfigManager:GetAllRidePet(PetID)
  local Scale = 1
  if PetConf.model_scale and 0 ~= PetConf.model_scale then
    Scale = PetConf.model_scale / 100
  else
    local PetBaseConf = DataConfigManager:GetPetbaseConf(PetID)
    if PetBaseConf then
      local modelConfId = PetBaseConf.model_conf
      local modelConf = DataConfigManager:GetModelConf(modelConfId)
      if modelConf and modelConf.model_scale and 0 ~= modelConf.model_scale then
        Scale = modelConf.model_scale / 100
      else
        Log.Error("BP_RideComponent_C:SetRelativeTransform \230\178\161\230\156\137\230\137\190\229\136\176\230\168\161\229\158\139\231\188\169\230\148\190 \230\136\150\231\188\169\230\148\190\230\149\176\230\141\174\229\188\130\229\184\184 ID = " .. modelConfId)
      end
    else
      Log.Error("BP_RideComponent_C:SetRelativeTransform \230\178\161\230\156\137\230\137\190\229\136\176\231\178\190\231\129\181Base ID = " .. PetID)
    end
  end
  local ignoreActors = UE4.TArray(UE.AActor)
  ignoreActors:Add(self.Rider)
  self.CapsuleHalfHeight = PetConf.capsule_half_height
  self.CapsuleRadius = PetConf.capsule_radius
  if self.CapsuleHalfHeight * Scale < self.MinCapsuleHalfHeight then
    self.CapsuleHalfHeight = self.MinCapsuleHalfHeight / Scale
  end
  if self.CapsuleRadius * Scale < self.MinCapsuleRadius then
    self.CapsuleRadius = self.MinCapsuleRadius / Scale
  end
  self.RelativeMeshTranslation:Set(tonumber(PetConf.mesh_offset_x), tonumber(PetConf.mesh_offset_y), tonumber(PetConf.mesh_offset_z))
  local CheckType = ProtoEnum.SceneRideAllType.SRAT_GROUND
  if self:IsPetOnlyFly(PetID) then
    CheckType = ProtoEnum.SceneRideAllType.SRAT_FLY
  elseif self.RideMoveType == ProtoEnum.SceneRideAllType.SRAT_CLIMB then
    CheckType = ProtoEnum.SceneRideAllType.SRAT_CLIMB
  end
  local BaseLocation = self.Rider:Abs_K2_GetActorLocation()
  local BaseLocationNoAbs = self.Rider:K2_GetActorLocation()
  local ExtraLocation = UE.FVector(0, 0, 0)
  if not self:CheckRideRoom(CheckType, PetConf, ignoreActors, BaseLocation, ExtraLocation, Scale) then
    local SphereRadius = self.Rider.CapsuleComponent:GetScaledCapsuleRadius()
    local DebugType = UE.EDrawDebugTrace.None
    local HorizTraceChannel = UE4.UNRCStatics.ConvertToTraceChannel(UE4.ECollisionChannel.ECC_Camera)
    local WaterTraceChannel = UE4.UNRCStatics.ConvertToTraceChannel(UE4.ECollisionChannel.ECC_GameTraceChannel2)
    local AirWallTraceChannel = UE4.UNRCStatics.ConvertToTraceChannel(UE4.ECollisionChannel.ECC_GameTraceChannel14)
    if CheckType == ProtoEnum.SceneRideAllType.SRAT_CLIMB then
    else
      local ForwardDir = self.Rider:GetActorForwardVector()
      local ForwardRotator = UE.UKismetMathLibrary.Conv_VectorToRotator(-ForwardDir)
      for i = 0, 3 do
        local traceDir = UE.UKismetMathLibrary.Conv_RotatorToVector(UE.FRotator(0, i * 90 + ForwardRotator.Yaw, 0))
        ExtraLocation = traceDir * self.CapsuleRadius * Scale
        local traceEndLocation = BaseLocation + ExtraLocation
        local WaterHitResult, bWaterHit = UE.UKismetSystemLibrary.Abs_SphereTraceSingle(self.Rider, BaseLocation, traceEndLocation, SphereRadius, WaterTraceChannel, false, ignoreActors, DebugType, nil, true, UE.FLinearColor(0, 1, 0, 1), UE.FLinearColor(1, 0, 0, 1), 2)
        if bWaterHit then
          ignoreActors:Add(WaterHitResult.Actor)
        end
        local HitResult, bHit = UE.UKismetSystemLibrary.Abs_SphereTraceSingle(self.Rider, BaseLocation, traceEndLocation, SphereRadius, HorizTraceChannel, false, ignoreActors, DebugType, nil, true, UE.FLinearColor(0, 1, 0, 1), UE.FLinearColor(1, 0, 0, 1), 2)
        local AirHitResult, bAirHit = UE.UKismetSystemLibrary.Abs_SphereTraceSingle(self.Rider, BaseLocation, traceEndLocation, SphereRadius, AirWallTraceChannel, false, ignoreActors, DebugType, nil, true, UE.FLinearColor(0, 1, 0, 1), UE.FLinearColor(1, 0, 0, 1), 2)
        if not bHit and not bAirHit then
          local canRide = self:CheckRideRoom(CheckType, PetConf, ignoreActors, traceEndLocation, ExtraLocation, Scale)
          if canRide then
            return true
          end
        end
      end
    end
    local TipsText = "pet_eco_reject"
    if self.Rider.sceneCharacter.statusComponent:HasStatus(ProtoEnum.WorldPlayerStatusType.WPST_TRANSFORM) then
      TipsText = "transform_failed"
    end
    _G.NRCModeManager:DoCmd(TipsModuleCmd.TopHud_ShowTips, _G.LuaText[TipsText])
    self.bIsRoomFail = true
    return false
  end
  return true
end

function BP_RideComponent_C:CheckRideRoom(type, PetConf, ignoreActors, BaseLocation, ExtraLocation, Scale)
  local traceChannel = "Character"
  local hitUpResult, isUPHit, hitDownResult, isDownHit, UpPos, DownPos
  local DebugType = UE.EDrawDebugTrace.None
  local Pos
  local isLand = false
  local UpVector = self.Rider:GetActorUpVector()
  if type == ProtoEnum.SceneRideAllType.SRAT_FLY then
    local Z_Offset = 70
    if self.Rider.sceneCharacter.statusComponent:HasStatus(ProtoEnum.WorldPlayerStatusType.WPST_CLIMB) then
      Z_Offset = 20
    end
    self.RelativeTransform.Translation:Set(0, 0, self.CapsuleHalfHeight * Scale + Z_Offset - self.MinCapsuleRadius)
    Pos = BaseLocation + self.RelativeTransform.Translation
    UpPos = Pos + UE.UKismetMathLibrary.Multiply_VectorFloat(UpVector, (self.CapsuleHalfHeight - self.CapsuleRadius) * Scale)
    DownPos = Pos + UE.UKismetMathLibrary.Multiply_VectorFloat(UpVector, -(self.CapsuleHalfHeight - self.CapsuleRadius) * Scale)
  elseif type == ProtoEnum.SceneRideAllType.SRAT_CLIMB then
    local ForwardDir = self.Rider:GetActorForwardVector()
    self.RelativeTransform.Translation = UE.UKismetMathLibrary.Multiply_VectorFloat(ForwardDir, -(self.CapsuleRadius * Scale - self.MinCapsuleRadius + 1))
    Pos = BaseLocation + self.RelativeTransform.Translation
    UpPos = Pos + UE.UKismetMathLibrary.Multiply_VectorFloat(UpVector, (self.CapsuleHalfHeight - self.CapsuleRadius) * Scale + 1)
    DownPos = Pos + UE.UKismetMathLibrary.Multiply_VectorFloat(UpVector, -((self.CapsuleHalfHeight - self.CapsuleRadius) * Scale + 1))
  else
    isLand = true
    local offset = 50
    if not self.Rider.sceneCharacter.isLocal then
      offset = 0
    end
    self.RelativeTransform.Translation = UE.UKismetMathLibrary.Multiply_VectorFloat(UpVector, self.CapsuleHalfHeight * Scale - self.MinCapsuleHalfHeight + offset)
    Pos = BaseLocation + self.RelativeTransform.Translation
    local CapsuleData = self.CapsuleHalfHeight - self.CapsuleRadius
    if 0 == CapsuleData then
      UpPos = UE4.FVector(Pos.X, Pos.Y, Pos.Z + 1)
      DownPos = UE4.FVector(Pos.X, Pos.Y, Pos.Z)
    else
      UpPos = Pos + UE.UKismetMathLibrary.Multiply_VectorFloat(UpVector, CapsuleData * Scale)
      DownPos = Pos + UE.UKismetMathLibrary.Multiply_VectorFloat(UpVector, -(CapsuleData * Scale))
    end
  end
  if not self.Rider.sceneCharacter.isLocal then
    self.RelativeTransform.Translation = self.RelativeTransform.Translation + ExtraLocation
    return true
  end
  hitUpResult, isUPHit = UE.UKismetSystemLibrary.Abs_SphereTraceSingleByProfile(self.Rider, UpPos, DownPos, self.CapsuleRadius * Scale, traceChannel, false, ignoreActors, DebugType)
  hitDownResult, isDownHit = UE.UKismetSystemLibrary.Abs_SphereTraceSingleByProfile(self.Rider, DownPos, UpPos, self.CapsuleRadius * Scale, traceChannel, false, ignoreActors, DebugType)
  if isUPHit or isDownHit then
    return false
  end
  if isLand and (self.RideMoveType == ProtoEnum.SceneRideAllType.SRAT_GROUND or self.RideMoveType == ProtoEnum.SceneRideAllType.SRAT_SWIM) then
    local landTraceChannel = UE.ETraceTypeQuery.Land
    DownPos = Pos + UE.UKismetMathLibrary.Multiply_VectorFloat(UpVector, -((self.CapsuleHalfHeight - self.CapsuleRadius) * Scale) - 200)
    local landResult, islandHit = UE.UKismetSystemLibrary.Abs_SphereTraceSingle(self.Rider, UpPos, DownPos, self.CapsuleRadius * Scale, landTraceChannel, false, ignoreActors, DebugType)
    if self.RideMoveType == ProtoEnum.SceneRideAllType.SRAT_SWIM then
      self.RelativeTransform.Translation = UE.UKismetMathLibrary.Subtract_VectorVector(self.RelativeTransform.Translation, UE.FVector(0, 0, 50))
      self.RelativeTransform.Translation = self.RelativeTransform.Translation + ExtraLocation
      return true
    elseif not islandHit then
      return false
    end
    self.RelativeTransform.Translation = UE.UKismetMathLibrary.Add_VectorVector(landResult.Location, UE.FVector(0, 0, (self.CapsuleHalfHeight - self.CapsuleRadius) * Scale) + 2)
    self.RelativeTransform.Translation = UE.UKismetMathLibrary.Subtract_VectorVector(self.RelativeTransform.Translation, self.Rider:Abs_K2_GetActorLocation())
  end
  self.RelativeTransform.Translation = self.RelativeTransform.Translation + ExtraLocation
  return true
end

function BP_RideComponent_C:OnVitalityOver()
  if self.Rider.sceneCharacter and self.Rider.sceneCharacter.buffComponent then
    if self.Rider.sceneCharacter.statusComponent:HasStatus(ProtoEnum.WorldPlayerStatusType.WPST_TRANSFORM) then
      local buff = self.Rider.sceneCharacter.buffComponent:GetBuff("Transform_Buff")
      if buff then
        buff:OnVitalityOver()
      end
      return
    end
    local buff = self.Rider.sceneCharacter.buffComponent:GetBuff("RideAll_Main_Buff")
    if buff and buff.SkillConf and buff.SkillConf.vitality_cost.min_start and buff.SkillConf.vitality_cost.min_start > 0 then
      return
    end
  end
  if self:TryChangeToLink() then
    return
  end
  self:OnRideFailed()
end

function BP_RideComponent_C:RideNextPet()
  local player = self.Rider.sceneCharacter
  local oldId
  if self.ScenePet then
    oldId = self.ScenePet.config.id
  end
  local newId = 0
  local rideTable = DataConfigManager:GetTable(DataConfigManager.ConfigTableId.ALL_RIDE_PET):GetAllDatas()
  for _, v in pairs(rideTable) do
    newId = v.id
    break
  end
  if oldId then
    local flag = false
    for _, v in pairs(rideTable) do
      if flag then
        newId = v.id
        break
      end
      if oldId == v.id then
        flag = true
      end
    end
  end
  player.statusComponent:RemoveStatus(ProtoEnum.WorldPlayerStatusType.WPST_RIDEALL)
  local ScenePet = ScenePlayerPet(nil, newId, -ProtoEnum.SceneRideAllCustomGid.SRCG_LocalTest, player)
  self._abilityHelper:HandleStatus(player, ScenePet)
end

function BP_RideComponent_C:ShowDebugInfo(DeltaSeconds)
  if GlobalConfig.bShowRideAllMoveInfo then
    local _curConfig = self.ScenePet.owner.vitalityComponent._vitalityCostTable[ProtoEnum.WorldPlayerStatusType.WPST_RIDEALL]._curConfig
    local id, cost, idleCost, startCost
    if _curConfig then
      id = _curConfig.id
      cost = _curConfig.vitality_cost.cost_per_seconds
      idleCost = _curConfig.vitality_cost.idle_cost
      startCost = _curConfig.vitality_cost.start_cost
    else
      return
    end
    local cameraRight = UE.UKismetMathLibrary.GetRightVector(self.Rider.sceneCharacter:GetUEController().PlayerCameraManager:GetCameraRotation())
    local BaseLocation = UE.UKismetMathLibrary.Multiply_VectorFloat(cameraRight, 50)
    BaseLocation = UE.UKismetMathLibrary.Add_VectorVector(self.Rider:K2_GetActorLocation(), BaseLocation)
    local textLocation = UE.UKismetMathLibrary.Add_VectorVector(BaseLocation, UE.FVector(0, 0, 100))
    UE.UKismetSystemLibrary.DrawDebugString(self.Rider, textLocation, string.format("\231\167\187\229\138\168\230\168\161\229\188\143\239\188\154%s, \231\148\159\230\149\136\230\138\128\232\131\189\239\188\154%s", table.getKeyName(ProtoEnum.SceneRideAllType, self.RideMoveType), table.getKeyName(ProtoEnum.SceneRideAllActiveType, _curConfig.active_type)), nil, UE4.FLinearColor(0, 1, 0, 1), 0)
    textLocation = UE.UKismetMathLibrary.Add_VectorVector(BaseLocation, UE.FVector(0, 0, 80))
    UE.UKismetSystemLibrary.DrawDebugString(self.Rider, textLocation, string.format("\228\189\147\229\138\155ID\239\188\154%d, idle\230\151\182\230\140\129\231\187\173\230\137\163\233\153\164\239\188\154%s", id, tostring(idleCost)), nil, UE4.FLinearColor(0, 1, 0, 1), 0)
    textLocation = UE.UKismetMathLibrary.Add_VectorVector(BaseLocation, UE.FVector(0, 0, 60))
    UE.UKismetSystemLibrary.DrawDebugString(self.Rider, textLocation, string.format("\229\144\175\229\138\168\230\151\182\228\189\147\229\138\155\230\137\163\233\153\164\239\188\154%d\239\188\140 \228\189\147\229\138\155\230\140\129\231\187\173\230\137\163\233\153\164\239\188\154%d/s", startCost, cost), nil, UE4.FLinearColor(0, 1, 0, 1), 0)
  end
end

function BP_RideComponent_C:UpdateHeadWidget()
  local player = self.Rider.sceneCharacter
  if player then
    local hudComponent = player.hudComponent
    if hudComponent then
      hudComponent:AdjustOffset()
    end
  end
end

function BP_RideComponent_C:UpdateHeadWidgetDoubleRide(InDoubleRide)
  local player = self.Rider.sceneCharacter
  if player then
    local hudComponent = player.hudComponent
    if player.isLocal then
      hudComponent = player.LocalPlayerHUDComponent
    end
    if hudComponent then
      if InDoubleRide then
        hudComponent:AdjustHudAfterDoubleRiding()
      else
        hudComponent:RestoreHudAfterDoubleRiding()
      end
    end
    if FriendModuleCmd then
      if InDoubleRide then
        _G.NRCModuleManager:DoCmd(_G.FriendModuleCmd.OnCmdStartOverrideAttachment, player.viewObj)
      else
        _G.NRCModuleManager:DoCmd(_G.FriendModuleCmd.OnCmdStopOverrideAttachment, player.viewObj)
      end
    end
  end
end

function BP_RideComponent_C:SetSmrInfo()
  local petId = self.ScenePet.config.id
  local PetBaseConf = DataConfigManager:GetPetbaseConf(petId)
  if not PetBaseConf then
    return
  end
  local modelId = PetBaseConf.model_conf
  UE.UDataTableFunctionLibrary.GetTableDataRowFromName(self.SmrInfo, modelId .. "", self.RidePet.SmrInfo)
end

function BP_RideComponent_C:PrepareForMutation(loadingList)
  local DiffMatType = self.SyncDiffMat
  local DiffNature = self.SyncDiffNature
  local GlassInfo = self.GlassInfo
  local petId = self.ScenePet.config.id
  if nil == DiffMatType or nil == DiffNature then
    return
  end
  self.petData = {
    mutation_type = DiffMatType,
    nature = DiffNature,
    glass_info = GlassInfo,
    base_conf_id = petId
  }
  local matNum = 0
  if PetMutationUtils.GetMutationValue(self.petData.mutation_type, _G.Enum.MutationDiffType.MDT_SHINING) then
    local PetBaseConf = DataConfigManager:GetPetbaseConf(petId)
    if PetBaseConf then
      local modelId = PetBaseConf.model_conf
      local smrInfo = UE4.FRideSMRData()
      UE.UDataTableFunctionLibrary.GetTableDataRowFromName(self.SmrInfo, modelId .. "", smrInfo)
      if smrInfo then
        local materialList = smrInfo.MaterialDetailList
        if materialList then
          for idx, mat in tpairs(materialList.Materials) do
            matNum = matNum + 1
            local matPath = UE4.UNRCStatics.GetSoftObjPath(mat)
            Log.Debug("BP_RideComponent_C:PrepareForMutation matPath", idx, matPath)
            table.insert(loadingList, matPath)
          end
        end
      end
    end
    self.petData.mutation_type = self.petData.mutation_type & ~_G.Enum.MutationDiffType.MDT_SHINING
    if 0 == matNum then
      Log.Debug("PetMutationUtils \229\188\130\232\137\178\230\157\144\232\180\168\233\133\141\231\189\174\228\184\186\231\169\186\239\188\129", petId)
    end
  end
end

function BP_RideComponent_C:DoColorDiffMutation(assets)
  local materials = {}
  for idx, mat in pairs(assets) do
    if UE4.UObject.IsValid(mat) and mat:IsA(UE4.UMaterialInterface) then
      table.insert(materials, mat)
    end
  end
  if 0 == #materials then
    return
  end
  local character = self.RidePet
  local originMaterialsSuffix = PetMutationUtils.GetMaterialsSuffixTable(character)
  for _, mat in pairs(materials) do
    PetMutationUtils.ApplyColorDiffMaterial(character, originMaterialsSuffix, mat)
  end
end

function BP_RideComponent_C:SetDiffMat()
  if not self.petData then
    return
  end
  PetMutationUtils.DoMutation(self.RidePet, self.petData)
end

function BP_RideComponent_C:CanPetSwim(MeshName)
  local petID = self._abilityHelper:GetIDByName(MeshName)
  local RideConf = DataConfigManager:GetAllRidePet(petID)
  for _, MovementId in pairs(RideConf.basic_movement_list) do
    local MoveConfOrigin = DataConfigManager:GetRideBasicMovement(MovementId)
    if MoveConfOrigin.move_type == ProtoEnum.SceneRideAllType.SRAT_SWIM then
      return true
    end
  end
  return false
end

function BP_RideComponent_C:CanPetWalk(MeshName)
  local petID = self._abilityHelper:GetIDByName(MeshName)
  local RideConf = DataConfigManager:GetAllRidePet(petID)
  for _, MovementId in pairs(RideConf.basic_movement_list) do
    local MoveConfOrigin = DataConfigManager:GetRideBasicMovement(MovementId)
    if MoveConfOrigin.move_type == ProtoEnum.SceneRideAllType.SRAT_GROUND then
      return true
    end
  end
  return false
end

function BP_RideComponent_C:CanPetFly(MeshName)
  local petID = self._abilityHelper:GetIDByName(MeshName)
  local RideConf = DataConfigManager:GetAllRidePet(petID)
  for _, MovementId in pairs(RideConf.basic_movement_list) do
    local MoveConfOrigin = DataConfigManager:GetRideBasicMovement(MovementId)
    if MoveConfOrigin.move_type == ProtoEnum.SceneRideAllType.SRAT_FLY then
      return true
    end
  end
  return false
end

function BP_RideComponent_C:IsPetOnlyFly(petID)
  local RideConf = DataConfigManager:GetAllRidePet(petID)
  if 1 == #RideConf.basic_movement_list then
    local MoveConfOrigin = DataConfigManager:GetRideBasicMovement(RideConf.basic_movement_list[1])
    if MoveConfOrigin.move_type == ProtoEnum.SceneRideAllType.SRAT_FLY then
      return true
    end
  end
  return false
end

function BP_RideComponent_C:UpdateDrawDebugFlag()
  if self.RidePet then
    self.RidePet.NeedDrawDebug = GlobalConfig.DrawRideCollision
  end
end

function BP_RideComponent_C:ChangeSocketWhileRiding(FullSocketName)
  if self.RidePet and "" ~= FullSocketName and nil ~= FullSocketName then
    local gender, slot_type, suffix = string.match(FullSocketName, "^(.-)_(.-)_Ride(.*)$")
    if self.RidePet.Mesh.SkeletalMesh:FindSocket(FullSocketName) then
      for SocketNameFormList, v in pairs(Enum.ScenePlayerRideSocketType) do
        if SocketNameFormList == slot_type then
          self.SocketName_Male = gender
          self.RideSocketName = FullSocketName
          self.SocketType = v
          self.SocketName_Head = slot_type
          self.SocketName_Tail = suffix
          self.RidePet.SocketType = self.SocketType
          local shouldSetPetOffset = self.RidePet.Mesh:GetAttachParent() ~= self.RidePet.CapsuleComponent
          self.Rider.Mesh:K2_AttachToComponent(self.Rider.CapsuleComponent, "None", UE4.EAttachmentRule.KeepWorld, UE4.EAttachmentRule.KeepWorld, UE4.EAttachmentRule.KeepWorld, true)
          self.RidePet.Mesh:K2_AttachToComponent(self.RidePet.CapsuleComponent, "None", UE4.EAttachmentRule.KeepWorld, UE4.EAttachmentRule.KeepWorld, UE4.EAttachmentRule.KeepWorld, true)
          self.Rider.Mesh:K2_SetRelativeTransform(self.CacheMeshTransform, false, nil, false)
          if shouldSetPetOffset then
            self.RidePet.Mesh:K2_SetRelativeLocation(self.RelativeMeshTranslation, false, nil, false)
          end
          self:ChangeAnimSocketName()
          self:AttachPet()
          self.Rider.sceneCharacter:SendEvent(PlayerModuleEvent.ON_RIDEPET_CHANGE_MOVETYPE)
          return true
        end
      end
    end
  end
  Log.Error("\233\157\158\233\170\145\228\185\152\231\138\182\230\128\129\230\136\150\230\143\146\230\167\189\229\144\141\233\148\153\232\175\175")
  return false
end

function BP_RideComponent_C:DoubleRide2p_Test(RidePet, SocketName)
  local statusId = ProtoEnum.WorldPlayerStatusType.WPST_RIDEALL
  local player = NRCModeManager:DoCmd(PlayerModuleCmd.GET_LOCAL_PLAYER)
  local customParams_1p = player.statusComponent._statusParams[statusId]
  local act = ProtoMessage:newSpaceAct_SyncPlayerStatus()
  local act_info = ProtoMessage:newPlayerStatusSyncInfo()
  act_info.custom_status_param = customParams_1p
  act_info.status = statusId
  act_info.sub_status = 1
  act_info.op_code = ProtoEnum.WPST_OpCode.WPST_OPCODE_SERVER_ADD
  act.sync_status_info_list = {act_info}
  customParams_1p.ride_param.double_ride_2p_id = self.Rider.sceneCharacter.serverData.base.actor_id
  self.Rider.sceneCharacter.statusComponent:OnReceiveSyncAction(act)
  local gender, slot_type, suffix = string.match(SocketName, "^(.-)_(.-)_Ride(.*)$")
  for SocketNameFormList, v in pairs(Enum.ScenePlayerRideSocketType) do
    if SocketNameFormList == slot_type then
      self.SocketName_Male = gender
      self.RideSocketName = SocketName
      self.SocketType = v
      self.SocketName_Head = slot_type
      self.SocketName_Tail = suffix
    end
  end
  self:DoubleRide2p(RidePet)
  self:ChangeAnimSocketName()
  self.bIsDoubleRide2p = true
  self.bIsLocalDebug = true
end

function BP_RideComponent_C:IsInDoubleRide()
  if not (self.Rider and self.Rider.sceneCharacter) or not self.Rider.sceneCharacter.statusComponent then
    return false
  end
  local statusId = ProtoEnum.WorldPlayerStatusType.WPST_RIDEALL
  local customParams = self.Rider.sceneCharacter.statusComponent:GetCustomParams(statusId)
  if customParams and customParams.ride_param and customParams.ride_param.double_ride_2p_id and customParams.ride_param.double_ride_2p_id > 0 then
    return true
  end
  return false
end

function BP_RideComponent_C:GetRideG6Path()
  local rideStartPath = "/Game/ArtRes/Effects/G6Skill/SceneEffect/Pet/Ride/NS_Scene_Ride_Open.NS_Scene_Ride_Open_C"
  local rideStopPath = "/Game/ArtRes/Effects/G6Skill/SceneEffect/Pet/Ride/NS_Scene_Ride_Close.NS_Scene_Ride_Close_C"
  return rideStartPath, rideStopPath
end

function BP_RideComponent_C:LoadByPath(MeshPath, ABPPath)
  local rideStartPath, rideStopPath = self:GetRideG6Path()
  self.bIsLoading = true
  self.LoadingList = {}
  table.insert(self.LoadingList, MeshPath)
  table.insert(self.LoadingList, ABPPath)
  table.insert(self.LoadingList, rideStartPath)
  table.insert(self.LoadingList, rideStopPath)
  self:CollectAllCurves(self.LoadingList)
  self:PrepareForMutation(self.LoadingList)
  self:PrepareResonanceAnimSeq(self.LoadingList)
  self.bIsRoomFail = false
  self.bIsFastLoading = true
  _G.PlayerResourceManager:LoadResources_PlayerLogic_List(self, self.LoadingList, self.Rider.sceneCharacter.isLocal, self.OnRideLoadSuccess, self.OnRideLoadFailed, function(id)
    self.curSessionId = id
  end)
  self.bIsFastLoading = false
end

function BP_RideComponent_C:CollectAllCurves(LoadingList)
  local petID = self.ScenePet.config.id
  local RideConf = DataConfigManager:GetAllRidePet(petID)
  for _, MovementId in pairs(RideConf.basic_movement_list) do
    local MoveConfOrigin = DataConfigManager:GetRideBasicMovement(MovementId)
    local MoveConf = _G.BinDataUtils.BinDataUnboxing(MoveConfOrigin, false)
    local kvMode = false
    for k, v in pairs(MoveConf) do
      if type(k) == "string" and type(v) == "string" and k:match("^move_param_") and string.find(v, ":") then
        local PropName, PropValue = string.match(v, "(.-):(.*)")
        if string.find(PropValue, "/") then
          local Folder, AssetName = string.match(v, "(.-)/(.*)")
          PropValue = "/Game/NewRoco/Modules/Core/Character/Rides/RideAll/RideCurve/" .. PropValue .. "." .. AssetName
          table.insert(LoadingList, PropValue)
        end
      end
    end
  end
  for _, ActiveSkillId in pairs(RideConf.active_skill_list) do
    local MoveConfOrigin = DataConfigManager:GetRideBasicMovement(ActiveSkillId)
    local MoveConf = _G.BinDataUtils.BinDataUnboxing(MoveConfOrigin, false)
    if MoveConf then
      for k, v in pairs(MoveConf) do
        if type(k) == "string" and type(v) == "string" and k:match("^move_param_") and string.find(v, "RideCurve") then
          table.insert(LoadingList, v)
        end
      end
    end
  end
end

function BP_RideComponent_C:PrepareResonanceAnimSeq(LoadingList)
  local Player = self.Rider.sceneCharacter
  local petID = self.ScenePet.config.id
  local RideConf = DataConfigManager:GetAllRidePet(petID)
  for _, PassiveSkillID in pairs(RideConf.passive_skill) do
    local PassiveSkillConf = DataConfigManager:GetRidePassiveSkill(PassiveSkillID)
    if PassiveSkillConf.type == Enum.RidePetPassiveSkillType.RPPST_Resonance then
      local AnimName = tostring(PassiveSkillConf.param_3)
      if "" ~= AnimName then
        table.insert(LoadingList, string.format("AnimSequence'/Game/ArtRes/AnimSequence/Human/PC/PC1/Animation/%s.%s'", AnimName, AnimName))
        table.insert(LoadingList, string.format("AnimSequence'/Game/ArtRes/AnimSequence/Human/PC/PC2/Animation/%s.%s'", AnimName, AnimName))
      end
    end
  end
end

function BP_RideComponent_C:OnRideLoadSuccess(assets, sessionId)
  if not UE.UObject.IsValid(self) then
    return
  end
  if self.curSessionId ~= sessionId then
    Log.Error("\233\170\145\228\185\152\229\188\130\230\173\165\229\138\160\232\189\189\229\155\158\232\176\131\230\151\182\239\188\140\229\183\178\229\143\150\230\182\136\233\170\145\228\185\152", self.curSessionId, sessionId)
    return
  end
  self.bIsLoading = false
  self.Rider.Mesh.bEabledAuxiliaryAnimGraphThread = false
  self._rideUpFxClassRef = UnLua.Ref(assets[3])
  self._rideUpFxClass = assets[3]
  self._rideDownFxClassRef = UnLua.Ref(assets[4])
  self._rideDownFxClass = assets[4]
  self.Overridden.AfterLoadAsset(self, assets[1], assets[2])
  self:DoColorDiffMutation(assets)
end

function BP_RideComponent_C:OnRideLoadFailed(assets, sessionId)
  if self.curSessionId ~= sessionId then
    Log.Error("\233\170\145\228\185\152\229\188\130\230\173\165\229\138\160\232\189\189\229\155\158\232\176\131\230\151\182\239\188\140\229\183\178\229\143\150\230\182\136\233\170\145\228\185\152")
    return
  end
  self:OnRideFailed()
  self:StopRide()
end

function BP_RideComponent_C:GetPetBaseID()
  if self.ScenePet then
    return self.ScenePet.config.id
  end
  if self.bIsDoubleRide2p then
    local Id = ProtoEnum.WorldPlayerStatusType.WPST_RIDEALL
    local customParams = self.Rider.sceneCharacter.statusComponent:GetCustomParams(Id)
    if customParams then
      local uin_1p = customParams.ride_param.double_ride_1p_id
      local player_1p = _G.NRCModuleManager:DoCmd(_G.PlayerModuleCmd.GetPlayerByServerID, uin_1p)
      if player_1p then
        local customParams_1P = player_1p.statusComponent:GetCustomParams(Id)
        if customParams_1P then
          return customParams_1P.ride_param.ride_pet_id
        end
      end
    end
  end
  return nil
end

function BP_RideComponent_C:BindFxList()
  if not self.RidePet then
    return
  end
  local fxList = self.RidePet.SmrInfo.CustomPSC
  local mutation_type = self.SyncDiffMat
  if mutation_type and PetMutationUtils.GetMutationValue(mutation_type, _G.Enum.MutationDiffType.MDT_SHINING) then
    local fxListColorDiff = self.RidePet.SmrInfo.ColorDiffCustomPSC
    if fxListColorDiff and fxListColorDiff:Num() > 0 then
      fxList = fxListColorDiff
    end
  end
  self.RidePet.SelfFxList = fxList
  if not self.RidePet.FxIDs then
    self.RidePet.FxIDs = {}
    self.RidePet.PendingFx = {}
    self.RidePet.NightmareFxPathToInst = {}
  end
  for _, FXSetting in tpairs(self.RidePet.SelfFxList) do
    if FXSetting then
      local AssetPath = tostring(FXSetting.Template)
      if _G.NRCResourceManager:IsValidLoad() then
        local req = _G.NRCResourceManager:LoadResAsync(self, AssetPath, -1, 10, self.FxLoadSucc, self.FxLoadFail)
        self.RidePet.PendingFx[req] = FXSetting
      elseif _G.RocoEnv.IS_EDITOR then
        local InstID = self.RidePet.RocoFX:PlayFx_Name_Transform(UE.UObject.Load(AssetPath), FXSetting.BoneName, FXSetting.Transform, true, 0)
        table.insert(self.RidePet.FxIDs, InstID)
      end
    end
  end
end

function BP_RideComponent_C:FxLoadSucc(req, fxClass)
  if not UE.UObject.IsValid(self) then
    return
  end
  if not self.RidePet or not UE.UObject.IsValid(self.RidePet) then
    return
  end
  local FXSetting = self.RidePet.PendingFx and self.RidePet.PendingFx[req]
  local FXComp = self.RidePet.RocoFX
  if not FXSetting or not FXComp then
    return
  end
  self.RidePet.PendingFx[req] = nil
  NRCResourceManager:UnLoadRes(req)
  local InstID = FXComp:PlayFx_Name_Transform(fxClass, FXSetting.BoneName, FXSetting.Transform, true, 0)
  if self.RidePet.needHideSelf then
    self.RidePet.RocoFX:ShowHideFxByID(InstID, false)
  end
  table.insert(self.RidePet.FxIDs, InstID)
  local Comp = self.RidePet.RocoFX
  if not Comp then
    return
  end
  local FxCom = Comp:GetFxSystemComponentById(InstID)
  if FxCom and self.RidePet.alpha then
    FxCom:SetFloatParameter("Common_Xray", 1 - self.RidePet.alpha)
  end
end

function BP_RideComponent_C:FxLoadFail(req, msg)
  if not self.RidePet then
    return
  end
  if not self.RidePet.PendingFx then
    return
  end
  self.PendingFx[req] = nil
  NRCResourceManager:UnLoadRes(req)
end

function BP_RideComponent_C:OnDoubleNotify(Notify)
  Log.Debug("ZoneSceneDoubleRideNotify " .. Notify.area_id .. " " .. Notify.op .. " " .. Notify.leave_reson)
  if Notify then
    local player = NRCModuleManager:DoCmd(PlayerModuleCmd.GET_LOCAL_PLAYER)
    if self.Rider and self.Rider.sceneCharacter then
      player = self.Rider.sceneCharacter
    end
    local Id = ProtoEnum.WorldPlayerStatusType.WPST_RIDEALL
    if Notify.op == ProtoEnum.DOUBLE_RIDE_OPERATE.DRO_OPEN_POP_UP then
      _G.NRCModuleManager:DoCmd(TipsModuleCmd.TopHud_ShowTips, "\229\137\141\230\150\185\231\166\187\229\188\128\228\186\146\232\167\129\229\140\186\229\176\134\232\167\163\233\153\164\229\144\140\232\161\140\231\138\182\230\128\129")
      self.area_id = Notify.area_id
      _G.NRCModuleManager:DoCmd(_G.AirWallModuleCmd.DisplayVisualWall, Notify.area_id)
    end
    if Notify.op == ProtoEnum.DOUBLE_RIDE_OPERATE.DRO_CLOSE_POP_UP then
      self.area_id = nil
      _G.NRCModuleManager:DoCmd(_G.AirWallModuleCmd.HideVisualWall, Notify.area_id)
    end
    if Notify.op == ProtoEnum.DOUBLE_RIDE_OPERATE.DRO_ENTER_RIDE_AS_MASTER then
      local customParams = player.statusComponent._statusParams[Id]
      customParams = customParams or ProtoMessage:newPlayerStatusCustomParams()
      if nil == customParams.ride_param then
        customParams.ride_param = {}
      end
      customParams.ride_param.double_ride_2p_id = Notify.mate_id
      player.statusComponent:RefreshStatus(Id, 1, ProtoEnum.WPST_OpCode.WPST_OPCODE_REFRESH, customParams)
      if not self:IsInDoubleRide() then
        self:DoubleRideFail()
      end
    end
    if Notify.op == ProtoEnum.DOUBLE_RIDE_OPERATE.DRO_ENTER_RIDE_AS_MATE then
      if player.statusComponent:HasStatus(Id) then
        local customParams = player.statusComponent._statusParams[Id]
        customParams.ride_param.unride_flag = 1
        player.statusComponent:RefreshStatus(Id, 1, ProtoEnum.WPST_OpCode.WPST_OPCODE_REFRESH, customParams)
        player.statusComponent:RemoveStatus(Id)
      end
      local customParams = ProtoMessage:newPlayerStatusCustomParams()
      if nil == customParams.ride_param then
        customParams.ride_param = {}
      end
      customParams.ride_param.double_ride_1p_id = Notify.mate_id
      customParams.ride_param.double_ride_2p_id = player.serverData.base.actor_id
      player.statusComponent:ApplyStatus(Id, nil, nil, customParams)
      if not self:IsInDoubleRide() then
        self:DoubleRideFail()
      end
    end
    if Notify.op == ProtoEnum.DOUBLE_RIDE_OPERATE.DRO_LEAVE and self:IsInDoubleRide() then
      local customParams = player.statusComponent._statusParams[Id]
      customParams = customParams or ProtoMessage:newPlayerStatusCustomParams()
      if nil == customParams.ride_param then
        customParams.ride_param = {}
      end
      if customParams.ride_param.double_ride_1p_id == player.serverData.base.actor_id then
        customParams.ride_param.double_ride_2p_id = nil
        player.statusComponent:RefreshStatus(Id, 1, ProtoEnum.WPST_OpCode.WPST_OPCODE_REFRESH, customParams)
        player:SendEvent(PlayerModuleEvent.ON_STATUS_REFRESH, Id, 1, ProtoEnum.WPST_OpCode.WPST_OPCODE_REFRESH)
      else
        player.statusComponent:RemoveStatus(Id)
      end
    end
  end
end

function BP_RideComponent_C:DoubleRideFail()
end

function BP_RideComponent_C:CanBeDoubleRide1p()
  local player
  if self.Rider and self.Rider.sceneCharacter then
    player = self.Rider.sceneCharacter
  end
  if player then
    if player.isLocal then
      return self:ScenePetIsDoubleRide(self.ScenePet)
    else
      local customParams = player.statusComponent:GetCustomParams(ProtoEnum.WorldPlayerStatusType.WPST_RIDEALL)
      if customParams and customParams.ride_param.double_ride_1p_id == player.serverData.base.actor_id then
        return true
      end
    end
  end
  return false
end

function BP_RideComponent_C:RidePetHasDoubleRideSocket(PetID)
  local SocketRideConf = DataConfigManager:GetRideSocket(PetID, true)
  if SocketRideConf and SocketRideConf.double_ride_socket_pc1_1p then
    return true
  end
  return false
end

function BP_RideComponent_C:ScenePetIsDoubleRide(ScenePet)
  if ScenePet and ScenePet.config then
    if ScenePet.canDoubleRide == nil then
      ScenePet.canDoubleRide = self:IsDoubleRidePet(ScenePet, false)
    end
    return ScenePet.canDoubleRide
  end
  return false
end

function BP_RideComponent_C:IsDoubleRidePet(ScenePet, IgnoreTalent)
  if not ScenePet then
    return false
  end
  local PetID = ScenePet.config.id
  if self:RidePetHasDoubleRideSocket(PetID) then
    if IgnoreTalent then
      return true
    end
    local PetData = ScenePet:GetPetData()
    if not PetData or not PetData.real_speciality_ids then
      return false
    end
    for _, v in pairs(PetData.real_speciality_ids) do
      local TalentConf = DataConfigManager:GetPetTalentConf(v, true)
      if TalentConf then
        for _, Effect in pairs(TalentConf.effect_group) do
          if Effect.effect == ProtoEnum.PetTalentEffect.PTE_TWO_PLAYER_MOUNT then
            return true
          end
        end
      end
    end
  end
  return false
end

function BP_RideComponent_C:OnDoubleNotifyEnd()
  local player = NRCModuleManager:DoCmd(PlayerModuleCmd.GET_LOCAL_PLAYER)
  if self.Rider and self.Rider.sceneCharacter then
    player = self.Rider.sceneCharacter
  end
  local Id = ProtoEnum.WorldPlayerStatusType.WPST_RIDEALL
  if self:IsInDoubleRide() then
    local customParams = player.statusComponent._statusParams[Id]
    customParams = customParams or ProtoMessage:newPlayerStatusCustomParams()
    if customParams.ride_param == nil then
      customParams.ride_param = {}
    end
    if customParams.ride_param.double_ride_1p_id == player.serverData.base.actor_id then
      customParams.ride_param.double_ride_2p_id = nil
      player.statusComponent:RefreshStatus(Id, 1, ProtoEnum.WPST_OpCode.WPST_OPCODE_REFRESH, customParams)
      player:SendEvent(PlayerModuleEvent.ON_STATUS_REFRESH, Id, 1, ProtoEnum.WPST_OpCode.WPST_OPCODE_REFRESH)
    else
      player.statusComponent:RemoveStatus(Id)
    end
  end
end

function BP_RideComponent_C:OnDoubleNotifyBegin(Uin1, Uin2)
  Log.Debug("BP_RideComponent_C:OnDoubleNotifyBegin", Uin1, Uin2)
  local player = NRCModuleManager:DoCmd(PlayerModuleCmd.GET_LOCAL_PLAYER)
  if self.Rider and self.Rider.sceneCharacter then
    player = self.Rider.sceneCharacter
  end
  local Id = ProtoEnum.WorldPlayerStatusType.WPST_RIDEALL
  if not Uin1 or not Uin2 then
    Log.Error("\229\143\140\228\186\186\233\170\145\228\185\152\229\188\128\229\167\139\230\151\182\230\156\170\230\148\182\229\136\176UIN")
    return
  end
  local player1P = _G.NRCModuleManager:DoCmd(_G.PlayerModuleCmd.GetPlayerByUin, Uin1)
  local player2P = _G.NRCModuleManager:DoCmd(_G.PlayerModuleCmd.GetPlayerByUin, Uin2)
  if player == player1P then
    local customParams = player.statusComponent._statusParams[Id]
    customParams = customParams or ProtoMessage:newPlayerStatusCustomParams()
    if customParams.ride_param == nil then
      customParams.ride_param = {}
    end
    customParams.ride_param.double_ride_2p_id = player2P.serverData.base.actor_id
    player.statusComponent:RefreshStatus(Id, 1, ProtoEnum.WPST_OpCode.WPST_OPCODE_REFRESH, customParams)
    if not self:IsInDoubleRide() then
      self:DoubleRideFail()
    end
  else
    if player.statusComponent:HasStatus(Id) and player.isLocal then
      local customParams = player.statusComponent._statusParams[Id]
      customParams.ride_param.unride_flag = 1
      player.statusComponent:RefreshStatus(Id, 1, ProtoEnum.WPST_OpCode.WPST_OPCODE_REFRESH, customParams)
      player.statusComponent:RemoveStatus(Id)
    end
    local customParams = ProtoMessage:newPlayerStatusCustomParams()
    if customParams.ride_param == nil then
      customParams.ride_param = {}
    end
    customParams.ride_param.double_ride_1p_id = player1P.serverData.base.actor_id
    customParams.ride_param.double_ride_2p_id = player.serverData.base.actor_id
    if player.isLocal then
      player.statusComponent:ApplyStatus(Id, nil, nil, customParams)
    else
      player.statusComponent:PreChangeStatus(Id, 1, ProtoEnum.WPST_OpCode.WPST_OPCODE_ADD, customParams)
    end
    if not self:IsInDoubleRide() then
      self:DoubleRideFail()
    end
  end
end

function BP_RideComponent_C:TryChangeToLink()
  if not self.RideMoveComp or not UE4.UObject.IsValid(self.RideMoveComp) then
    return false
  end
  if self.RideMoveComp.MovementMode == UE.EMovementMode.MOVE_Walking or self.RideMoveComp.MovementMode == UE.EMovementMode.MOVE_Falling or self.RideMoveComp.MovementMode == UE.EMovementMode.MOVE_Custom and (self.RideMoveComp.CustomMovementMode == UE.ERocoCustomMovementMode.MOVE_Gliding or self.RideMoveComp.CustomMovementMode == UE.ERocoCustomMovementMode.MOVE_ClimbWater) or self.RideMoveComp.MovementMode == UE.EMovementMode.MOVE_Swimming and self.RidePet.CharacterSwimMovement:GetWaterDepth() < 120 then
    local player = self.Rider.sceneCharacter
    local RideParam = player.statusComponent:GetCustomParams(ProtoEnum.WorldPlayerStatusType.WPST_RIDEALL)
    if RideParam and RideParam.ride_param.double_ride_2p_id and RideParam.ride_param.double_ride_2p_id > 0 then
      local actor_2p_id = RideParam.ride_param.double_ride_2p_id
      local player2P = _G.NRCModuleManager:DoCmd(_G.PlayerModuleCmd.GetPlayerByServerID, actor_2p_id)
      if player.isLocal and player.InviteComponent._interactType then
        player:ForceSendMoveReq()
      end
      if player2P and player.InviteComponent:PreChangeTogether(ProtoEnum.RelationInteractSubType.RIST_HOLD_HANDS) then
        self:OnRideFailed()
        self.Rider.EnvInfoComponent:ForceUpdateSurfaceImmediately()
        self.Rider.CharacterMovement:UpdateWaterDepth()
        if self.Rider.CharacterMovement:GetImmergeWaterDepth() > 0 then
          self.Rider.MoveFXComponent:OnLandImpl(false, true)
        end
        local custom_params = ProtoMessage.newPlayerStatusCustomParams()
        custom_params.player_interact_param.player_uin1 = player.serverData.base.logic_id
        custom_params.player_interact_param.player_uin2 = player2P.serverData.base.logic_id
        local HandStatus = ProtoEnum.WorldPlayerStatusType.WPST_HAND_IN_HAND
        player.InviteComponent.CurStatus = HandStatus
        player2P.statusComponent:PreChangeStatus(ProtoEnum.WorldPlayerStatusType.WPST_RIDEALL, 1, ProtoEnum.WPST_OpCode.WPST_OPCODE_REMOVE)
        local handSuccess = player.InviteComponent:HandInHandLink(custom_params, HandStatus)
        player.InviteComponent:EndChangeTogether()
        if not handSuccess then
          player.InviteComponent:InteractCancel()
        else
          player2P.statusComponent:PreChangeStatus(ProtoEnum.WorldPlayerStatusType.WPST_HAND_IN_HAND_2P, 1, ProtoEnum.WPST_OpCode.WPST_OPCODE_ADD, custom_params)
        end
        player:SendEvent(PlayerModuleEvent.ON_UPDATE_TOGETHER)
        return true
      end
    end
  end
  return false
end

function BP_RideComponent_C:TryChangeToLinkWhileRoomFail()
  local player = self.Rider.sceneCharacter
  local RideParam = player.statusComponent:GetCustomParams(ProtoEnum.WorldPlayerStatusType.WPST_RIDEALL)
  if RideParam and RideParam.ride_param.double_ride_2p_id and RideParam.ride_param.double_ride_2p_id > 0 then
    local actor_2p_id = RideParam.ride_param.double_ride_2p_id
    local player2P = _G.NRCModuleManager:DoCmd(_G.PlayerModuleCmd.GetPlayerByServerID, actor_2p_id)
    if player.isLocal and player.InviteComponent._interactType then
      player:ForceSendMoveReq()
    end
    _G.NRCModuleManager:DoCmd(_G.PlayerModuleCmd.SyncStatusImmediately)
    if player2P and player.InviteComponent:PreChangeTogether(ProtoEnum.RelationInteractSubType.RIST_HOLD_HANDS) then
      self:OnRideFailed()
      self.Rider.EnvInfoComponent:ForceUpdateSurfaceImmediately()
      self.Rider.CharacterMovement:UpdateWaterDepth()
      if self.Rider.CharacterMovement:GetImmergeWaterDepth() > 0 then
        self.Rider.MoveFXComponent:OnLandImpl(false, true)
      end
      local custom_params = ProtoMessage.newPlayerStatusCustomParams()
      custom_params.player_interact_param.player_uin1 = player.serverData.base.logic_id
      custom_params.player_interact_param.player_uin2 = player2P.serverData.base.logic_id
      local HandStatus = ProtoEnum.WorldPlayerStatusType.WPST_HAND_IN_HAND
      player.InviteComponent.CurStatus = HandStatus
      player2P.statusComponent:PreChangeStatus(ProtoEnum.WorldPlayerStatusType.WPST_RIDEALL, 1, ProtoEnum.WPST_OpCode.WPST_OPCODE_REMOVE)
      local handSuccess = player.InviteComponent:HandInHandLink(custom_params, HandStatus)
      player.InviteComponent:EndChangeTogether()
      if not handSuccess then
        player.InviteComponent:InteractCancel()
      else
        player2P.statusComponent:PreChangeStatus(ProtoEnum.WorldPlayerStatusType.WPST_HAND_IN_HAND_2P, 1, ProtoEnum.WPST_OpCode.WPST_OPCODE_ADD, custom_params)
      end
      player:SendEvent(PlayerModuleEvent.ON_UPDATE_TOGETHER)
      return true
    end
  end
  return false
end

function BP_RideComponent_C:DoubleRide2p(RidePet, PetId, Is2pLocal)
  if UE.UObject.IsValid(RidePet) then
    RidePet.CharacterMovement:SetReplicateMode(UE.EReplicateMovementMode.ERM_LERP)
    if Is2pLocal then
      local eyeViewOffset = _G.NRCModuleManager:DoCmd(_G.PlayerModuleCmd.GetRidePetEyeViewOffset, PetId, true)
      RidePet.EyesViewPointOffset = eyeViewOffset
    end
  end
  self.Overridden.DoubleRide2p(self, RidePet)
end

function BP_RideComponent_C:StopDoubleRide2p()
  if UE.UObject.IsValid(self.RidePet) then
    self.RidePet.CharacterMovement:SetReplicateMode(UE.EReplicateMovementMode.ERM_SIMULATE)
  end
  self.Overridden.StopDoubleRide2p(self)
end

return BP_RideComponent_C

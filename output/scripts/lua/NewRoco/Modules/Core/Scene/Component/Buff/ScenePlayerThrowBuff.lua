local Base = require("NewRoco.Modules.Core.Scene.Component.Buff.ScenePlayerBuff")
local PlayerModuleEvent = require("NewRoco.Modules.Core.PlayerModule.PlayerModuleEvent")
local StatType = require("NewRoco.Modules.Core.Scene.Component.Stat.StatType")
local AbilityID = require("NewRoco.Modules.Core.Scene.Component.Ability.AbilityID")
local AbilityHelperManager = require("NewRoco.Modules.Core.Scene.Component.Ability.AbilityHelperManager")
local MainUIModuleEvent = require("NewRoco.Modules.System.MainUI.MainUIModuleEvent")
local SceneUtils = require("NewRoco.Modules.Core.Scene.Common.SceneUtils")
local NPCModuleEvent = require("NewRoco.Modules.Core.NPC.NPCModuleEvent")
local ScenePlayerThrowBuff = Base:Extend("ScenePlayerThrowBuff")

function ScenePlayerThrowBuff:newThrowSkillBuffInfo()
  return {
    ThrowInfo = nil,
    BallLua = nil,
    BallInfo = nil,
    maxSpeedCurve = nil,
    typedConfig = nil,
    ThrowBallHeavy = nil,
    ThrowBallLight = nil,
    ThrowG6SkillClass = nil,
    FastThrowAngleOffset = nil,
    AimThrowSpeedOffset = nil,
    HeavyThrowAngle = nil,
    ThrowStat = nil
  }
end

function ScenePlayerThrowBuff:Ctor(owner, ...)
  Base.Ctor(self, owner)
  self.LocalMode = false
end

function ScenePlayerThrowBuff:OnBegin(owner, SkillInfo)
  self.LocalMode = false
  if SkillInfo.ThrowInfo == nil or -1 == SkillInfo.ThrowInfo.ThrowItemType then
    self.LocalMode = true
    self.SkillInfo = SkillInfo
    self.SkillInfo.ThrowInfo = {}
    self:UpdateDirection()
    self.owner.viewObj.BP_ALSComponent:SetAimThrowState(true, false, self.FaceDirection, nil == self.owner.viewObj.RidePet)
    self:GetController():ChangeThrowAimStat(true)
    self.owner:AddEventListener(self, PlayerModuleEvent.ON_END_THROW, self.EndThrow)
    self.owner:AddEventListener(self, PlayerModuleEvent.ON_SWITCH_THROW, self.OnModeChange)
    self.owner:AddEventListener(self, PlayerModuleEvent.ON_THROW_INFO_CHANGE, self.OnBallChange)
    return
  end
  self.SkillInfo = SkillInfo
  self.LockedTarget = SkillInfo.ThrowInfo.AutoAimNPC
  self.lazySyncTime = _G.DataConfigManager:GetGlobalConfigNumByKeyType("lazy_move_sync_time", _G.DataConfigManager.ConfigTableId.GLOBAL_CONFIG, 100)
  self.Strength = SkillInfo.BallInfo.Strength
  self.Gravity = SkillInfo.BallInfo.Gravity / 1000
  self.isFast = false
  self.hasMode = false
  self.inThrow = false
  self._keepStill = true
  self:UpdateDirection()
  if self.SkillInfo.ThrowStat == Enum.SceneThrowAbilityType.STAT_NORMAL then
    self.owner.viewObj.BP_ALSComponent:SetAimThrowState(true, self.isFast, self.FaceDirection, true)
    self:ClampViewYaw()
    self.owner.viewObj:K2_SetActorRotation(UE4.FRotator(0, self:GetController():GetControlRotation().Yaw, 0), false)
  else
    self.owner.viewObj.BP_ALSComponent:SetAimThrowState(true, self.isFast, self.FaceDirection, false)
    local RideComponent = self.owner.viewObj.BP_RideComponent
    if RideComponent and not RideComponent:IsInDoubleRide() then
      self:GetController():ChangeThrowAimStat(true)
    end
    local RidePet = self.owner.viewObj.RidePet
    if RidePet and self.owner.statusComponent:HasStatus(ProtoEnum.WorldPlayerStatusType.WPST_RIDEALL) then
      self._keepStill = 0 == RidePet.CharacterMovement.Velocity:Size()
      if self._keepStill and (nil == RidePet.CharacterClimbMovement or false == RidePet.CharacterClimbMovement:IsClimbing()) then
        RidePet:K2_SetActorRotation(UE4.FRotator(0, self:GetController().PlayerCameraManager:GetCameraRotation().Yaw, 0), false)
      end
    end
  end
  self:ClampViewPitch()
  self._beginRotation = self:GetController():GetControlRotation()
  self.owner:AddEventListener(self, PlayerModuleEvent.ON_END_THROW, self.EndThrow)
  self.owner:AddEventListener(self, PlayerModuleEvent.ON_SWITCH_THROW, self.OnModeChange)
  self.owner:AddEventListener(self, PlayerModuleEvent.ON_STATUS_CHANGED, self.OnStatusChanged)
  self.owner:AddEventListener(self, PlayerModuleEvent.ON_THROW_INFO_CHANGE, self.OnBallChange)
  local Id = ProtoEnum.WorldPlayerStatusType.WPST_AIMTHROWING
  local customParams = self.owner.statusComponent._statusParams[Id]
  customParams = customParams or ProtoMessage:newPlayerStatusCustomParams()
  customParams.throw_aim_param.aim_type = ProtoEnum.AimSyncType.AST_INIT_AIM
  customParams.throw_aim_param.throw_item_type = SkillInfo.ThrowInfo.ThrowItemType
  customParams.throw_aim_param.throw_ball_id = self.SkillInfo.ThrowInfo.ThrowItemInfo.id
  if 1 == SkillInfo.ThrowInfo.ThrowItemType then
    customParams.throw_aim_param.throw_ball_id = self.SkillInfo.ThrowInfo.ThrowItemInfo.ball_id
  end
  customParams.throw_aim_param.throw_session_id = SkillInfo.BallLua.ThrowSession.SeqID
  self.owner.statusComponent:RefreshStatus(ProtoEnum.WorldPlayerStatusType.WPST_AIMTHROWING, 1, ProtoEnum.WPST_OpCode.WPST_OPCODE_REFRESH, customParams)
  self.owner.movementComponent:SetIsMoving(true, "Aim")
end

function ScenePlayerThrowBuff:OnStatusChanged(status, value, opCode)
  local throwHelper = AbilityHelperManager.GetHelper(AbilityID.AIM_THROW)
  if self.SkillInfo and self.SkillInfo.ThrowStat ~= throwHelper:GetThrowStat(self.owner) and self.caster then
    self.caster.statusComponent:RemoveStatus(Enum.WorldPlayerStatusType.WPST_AIMTHROWING, Enum.WPST_OpCode.WPST_OPCODE_REMOVE, 1)
  end
end

function ScenePlayerThrowBuff:OnModeChange(ThrowInfo)
  if self.LocalMode then
    return
  end
  if self.hasMode then
    return
  end
  self.hasMode = true
  self.SkillInfo.ThrowInfo = ThrowInfo
  local isFast = ThrowInfo.isFast
  self.isFast = false
  if isFast then
    self.isFast = true
  end
  self:UpdateDirection()
  if self.SkillInfo.ThrowStat == Enum.SceneThrowAbilityType.STAT_NORMAL then
    self.owner.viewObj.BP_ALSComponent:SetAimThrowState(true, self.isFast, self.FaceDirection, true)
    self._beginRotation = self:GetController():GetControlRotation()
    if not self.isFast then
      self:GetController():ChangeThrowAimStat(true)
      self:ClampViewPitch()
      local statComponent = self.owner.statComponent
      if self.SkillInfo.maxSpeedCurve then
        local characterMovement = self.owner.viewObj.CharacterMovement
        self._statMaxSpeedCurveID = statComponent:ApplyStat(StatType.MAX_WALK_SPEED_CURVE, self.SkillInfo.maxSpeedCurve, nil, characterMovement)
      end
    end
  else
    local AnimInstance = self.owner.viewObj.Mesh:GetAnimInstance()
    local RideAllAnimInstance = AnimInstance:GetLinkedAnimGraphInstanceByTag("RideAll")
    if nil == RideAllAnimInstance then
      AnimInstance.PlayThrow = true
    else
      RideAllAnimInstance.IsInterrupt = false
      RideAllAnimInstance.IsAiming = true
    end
  end
  if self.isFast then
    self:EndThrow(true)
  end
end

function ScenePlayerThrowBuff:OnBallChange(ThrowItemType, ThrowItemInfo)
  if not self.owner.statusComponent:HasStatus(ProtoEnum.WorldPlayerStatusType.WPST_AIMTHROWING) then
    return
  end
  local RidePet = self.owner.viewObj.BP_RideComponent.ScenePet
  if 1 == ThrowItemType and RidePet and ThrowItemInfo.gid == RidePet.gid then
    self.owner.statusComponent:RemoveStatus(Enum.WorldPlayerStatusType.WPST_AIMTHROWING, Enum.WPST_OpCode.WPST_OPCODE_REMOVE, 1)
    return
  end
  if self.SkillInfo.ThrowInfo.ThrowItemInfo and ThrowItemInfo.gid ~= self.SkillInfo.ThrowInfo.ThrowItemInfo.gid then
    self:ChangeBall(ThrowItemType, ThrowItemInfo)
  end
end

function ScenePlayerThrowBuff:EndThrow(Success)
  if self.inThrow then
    return
  end
  if Success then
    local BallStartPos = self:GetStartPos()
    local LocalPlayer = NRCModuleManager:DoCmd(PlayerModuleCmd.GET_LOCAL_PLAYER)
    local PlayerPos = LocalPlayer:GetActorLocation()
    local TraceChannel = UE4.UNRCStatics.ConvertToTraceChannel(UE4.ECollisionChannel.ECC_GameTraceChannel14)
    local HitResult, bHit = UE4.UKismetSystemLibrary.Abs_LineTraceSingle(_G.UE4Helper.GetCurrentWorld(), PlayerPos, BallStartPos, TraceChannel)
    if bHit then
      Success = false
    end
  end
  self.inThrow = true
  self:UpdateDirection()
  local Id = ProtoEnum.WorldPlayerStatusType.WPST_AIMTHROWING
  local customParams = self.owner.statusComponent._statusParams[Id]
  customParams = customParams or ProtoMessage:newPlayerStatusCustomParams()
  customParams.throw_aim_param.aim_type = ProtoEnum.AimSyncType.AST_END_THROW
  customParams.throw_aim_param.is_throw_success = Success
  customParams.throw_aim_param.throw_velocity = SceneUtils.ClientPos2ServerPos(self:CalculateVelocity())
  self.owner.statusComponent:RefreshStatus(ProtoEnum.WorldPlayerStatusType.WPST_AIMTHROWING, 1, ProtoEnum.WPST_OpCode.WPST_OPCODE_REFRESH, customParams)
  local endThrowHelper = AbilityHelperManager.GetHelper(AbilityID.END_THROW)
  if endThrowHelper then
    local statusComponent = self.owner.statusComponent
    for _, v in pairs(endThrowHelper.config.remove_status) do
      statusComponent:RemoveStatus(v, Enum.WPST_OpCode.WPST_OPCODE_REMOVE, 1, Success)
    end
  else
    Log.Error("\230\137\190\228\184\141\229\136\176\230\138\149\230\142\183\229\135\186\230\137\139\230\138\128\232\131\189")
  end
end

function ScenePlayerThrowBuff:OnUpdate(deltaTime)
  if GlobalConfig.ShowPreThrowTrajectory then
    self:UpdateDirection()
    self:DrawDebugTrajectory()
  end
  self._deltaTime = deltaTime
  self:ClampViewYaw()
  self:ChangeRideAngle(deltaTime)
  self:TrySnycRotation()
end

function ScenePlayerThrowBuff:CheckSelectedBall()
  if -1 == self.SkillInfo.ThrowInfo.ThrowItemType then
    return
  end
  if not self.owner.statusComponent:HasStatus(ProtoEnum.WorldPlayerStatusType.WPST_AIMTHROWING) then
    return
  end
  local gid = NRCModuleManager:DoCmd(MainUIModuleCmd.GetSelectedPetGid)
  if 0 ~= gid then
    if self.selectGid == nil then
      self.selectGid = gid
      self.SkillInfo.ThrowInfo.ThrowItemType = 1
    elseif 1 ~= self.SkillInfo.ThrowInfo.ThrowItemType or self.selectGid ~= gid then
      self:ChangeBall(1, gid)
    end
  else
    self.selectGid = gid
  end
end

function ScenePlayerThrowBuff:ChangeBall(ThrowItemType, ThrowItemInfo)
  local BallID, BallLua, ballNPC
  self.SkillInfo.ThrowInfo.ThrowItemType = ThrowItemType
  self.SkillInfo.ThrowInfo.ThrowItemInfo = ThrowItemInfo
  if not BagModuleCmd then
    return
  end
  NRCModuleManager:DoCmd(MainUIModuleCmd.ShowFrontSight, true)
  if 1 == ThrowItemType then
    BallLua = _G.NRCModuleManager:DoCmd(NPCModuleCmd.CreateThrowPetBall, ThrowItemInfo, self.owner:GetServerId())
    BallID = 100002
  else
    BallLua = _G.NRCModuleManager:DoCmd(NPCModuleCmd.CreateThrowBagItem, ThrowItemInfo, nil, self.owner:GetServerId())
    BallID = ThrowItemInfo.id
  end
  local BallInfo = DataConfigManager:GetBallAct(BallID)
  if nil == BallLua then
    Log.Error("\229\146\149\229\153\156\231\144\131\228\184\141\229\143\175\231\148\168")
    return
  end
  ballNPC = BallLua.viewObj
  if not UE4.UObject.IsValidLowLevel(ballNPC) then
    Log.Error("\229\146\149\229\153\156\231\144\131\228\184\141\229\143\175\231\148\168")
    return
  end
  if self.SkillInfo.BallLua then
    _G.NRCModuleManager:DoCmd(_G.NPCModuleCmd.DeleteThrowPetBall, self.SkillInfo.BallLua.viewObj)
  end
  local ProjectileMovement = ballNPC:GetComponentByClass(UE4.UProjectileMovementComponent)
  ProjectileMovement:SetActive(false)
  ballNPC:K2_AttachToComponent(self.owner.viewObj:GetComponentByClass(UE4.USkeletalMeshComponent), "locator_right_hand", UE4.EAttachmentRule.SnapToTarget, UE4.EAttachmentRule.SnapToTarget, UE4.EAttachmentRule.SnapToTarget, false)
  self.SkillInfo.BallLua = BallLua
  self.SkillInfo.BallInfo = BallInfo
  local Id = ProtoEnum.WorldPlayerStatusType.WPST_AIMTHROWING
  local customParams = self.owner.statusComponent._statusParams[Id]
  customParams = customParams or ProtoMessage:newPlayerStatusCustomParams()
  customParams.throw_aim_param.aim_type = ProtoEnum.AimSyncType.AST_BALL_CHANGE
  customParams.throw_aim_param.throw_item_type = self.SkillInfo.ThrowInfo.ThrowItemType
  customParams.throw_aim_param.throw_ball_id = self.SkillInfo.ThrowInfo.ThrowItemInfo.id
  if 1 == ThrowItemType then
    customParams.throw_aim_param.throw_ball_id = self.SkillInfo.ThrowInfo.ThrowItemInfo.ball_id
  end
  customParams.throw_aim_param.throw_session_id = BallLua.ThrowSession.SeqID
  self.owner.statusComponent:RefreshStatus(ProtoEnum.WorldPlayerStatusType.WPST_AIMTHROWING, 1, ProtoEnum.WPST_OpCode.WPST_OPCODE_REFRESH, customParams)
  _G.NRCEventCenter:DispatchEvent(NPCModuleEvent.ADD_THROW_SESSION_ITEM, BallLua.ThrowSession)
end

function ScenePlayerThrowBuff:OnFinish(param)
  local UIModule = _G.NRCModuleManager:GetModule("MainUIModule")
  if UIModule then
    UIModule:DispatchEvent(MainUIModuleEvent.UI_SHOW_AIM_JOYSTICK, false)
  end
  NRCModuleManager:DoCmd(MainUIModuleCmd.ShowFrontSight, false)
  self:RecoverView()
  self.owner.viewObj.BP_ALSComponent:SetAimThrowState(false, nil, nil, false)
  self:GetController().PlayerCameraManager.bOverRotator = false
  self:GetController():ChangeThrowAimStat(false)
  if self.SkillInfo.ThrowStat == Enum.SceneThrowAbilityType.STAT_NORMAL then
    if false == self.isFast then
      local characterMovement = self.owner.viewObj.CharacterMovement
      local statComponent = self.owner.statComponent
      if self.SkillInfo.maxSpeedCurve and self._statMaxSpeedCurveID ~= nil then
        statComponent:RemoveStat(StatType.MAX_WALK_SPEED_CURVE, self._statMaxSpeedCurveID, characterMovement)
      end
    end
  else
    self.owner.viewObj.ThrowHalfAngle = 0
  end
  self.SkillInfo = nil
  self.Strength = nil
  self.Gravity = nil
  self.isFast = nil
  self.hasMode = false
  self.inThrow = false
  self._beginRotation = nil
  self.owner:RemoveEventListener(self, PlayerModuleEvent.ON_END_THROW, self.EndThrow)
  self.owner:RemoveEventListener(self, PlayerModuleEvent.ON_SWITCH_THROW, self.OnModeChange)
  self.owner:RemoveEventListener(self, PlayerModuleEvent.ON_STATUS_CHANGED, self.OnStatusChanged)
  self.owner:RemoveEventListener(self, PlayerModuleEvent.ON_THROW_INFO_CHANGE, self.OnBallChange)
  self.owner.movementComponent:SetIsMoving(false, "Aim")
  self.owner = nil
end

function ScenePlayerThrowBuff:ClampViewPitch()
  if self.SkillInfo.typedConfig.limit_pitch then
    self:GetController().PlayerCameraManager.ViewPitchMin = self.SkillInfo.typedConfig.pitch_min
    self:GetController().PlayerCameraManager.ViewPitchMax = self.SkillInfo.typedConfig.pitch_max
  end
end

function ScenePlayerThrowBuff:ClampViewYaw()
  if self.LocalMode then
    return
  end
  if self.SkillInfo.typedConfig.limit_yaw and GlobalConfig.YawLimit.UseLimit then
    self:GetController().PlayerCameraManager.bOverRotator = true
    local YawMin = self.SkillInfo.typedConfig.yaw_min
    local YawMax = self.SkillInfo.typedConfig.yaw_max
    if GlobalConfig.YawLimit.UseLimit then
      YawMin = GlobalConfig.YawLimit.yaw_min or self.SkillInfo.typedConfig.yaw_min
      YawMax = GlobalConfig.YawLimit.yaw_max or self.SkillInfo.typedConfig.yaw_max
    end
    local PetRotation
    if self.owner.viewObj.RidePet then
      PetRotation = self.owner.viewObj.RidePet:K2_GetActorRotation()
    else
      PetRotation = self._beginRotation
    end
    self:GetController().PlayerCameraManager.ViewYawMin = PetRotation.Yaw + YawMin
    self:GetController().PlayerCameraManager.ViewYawMax = PetRotation.Yaw + YawMax
    if self.owner.viewObj.RidePet then
      self.owner.viewObj.RidePet.ViewYawMin = PetRotation.Yaw + YawMin
      self.owner.viewObj.RidePet.ViewYawMax = PetRotation.Yaw + YawMax
    end
  else
    local RidePet = self.owner.viewObj.RidePet
    if RidePet then
      RidePet.ViewYawMin = 0
      RidePet.ViewYawMax = 359.99
      local AnimInstance = self.owner.viewObj.Mesh:GetAnimInstance()
      if AnimInstance then
        local RideAllAnimInstance = AnimInstance:GetLinkedAnimGraphInstanceByTag("RideAll")
        if RideAllAnimInstance and RideAllAnimInstance.IsAiming then
          if RidePet.CharacterMovement.Velocity:Size() > 0 then
            RideAllAnimInstance.Angle = 0.0
            self._keepStill = false
          else
            local CameraYaw = self:GetController().PlayerCameraManager:GetCameraRotation().Yaw
            local PetYaw = RidePet:K2_GetActorRotation().Yaw
            local YawDiff = (CameraYaw - PetYaw + 180.0) % 360 - 180.0
            if YawDiff > 90.0 or YawDiff < -90.0 then
              local TargetYaw = CameraYaw
              YawDiff = UE4.UKismetMathLibrary.FClamp(YawDiff, -90.0, 90.0)
              if self._keepStill then
                TargetYaw = CameraYaw - YawDiff
              end
              if (RidePet.CharacterClimbMovement == nil or false == RidePet.CharacterClimbMovement:IsClimbing() or 0 == RidePet.CharacterClimbMovement.MovementMode) and (nil == RidePet.CharacterClimbWaterFallMovement or false == RidePet.CharacterClimbWaterFallMovement:IsClimbingWater() or 0 == RidePet.CharacterClimbWaterFallMovement.MovementMode) then
                RidePet:K2_SetActorRotation(UE4.FRotator(0, TargetYaw, 0), false)
              end
            end
            if self._keepStill then
              RideAllAnimInstance.Angle = YawDiff / 90.0
            else
              RideAllAnimInstance.Angle = 0
            end
            self._keepStill = true
          end
        end
      end
    end
  end
end

function ScenePlayerThrowBuff:ChangeRideAngle(deltaTime)
  if self.owner.viewObj.RidePet then
    local RidePet = self.owner.viewObj.RidePet
    local math = UE4.UKismetMathLibrary
    local PlayerForward = RidePet:GetActorForwardVector()
    local CameraForward = math.GetForwardVector(self:GetController():GetControlRotation())
    PlayerForward.Z = 0
    CameraForward.Z = 0
    PlayerForward = UE4.UKismetMathLibrary.Normal(PlayerForward)
    CameraForward = UE4.UKismetMathLibrary.Normal(CameraForward)
    local angle = math.DegAcos(math.Dot_VectorVector(PlayerForward, CameraForward))
    local PlayerRight = RidePet:GetActorRightVector()
    if math.Dot_VectorVector(PlayerRight, CameraForward) < 0 then
      angle = -angle
    end
    if not self.inThrow then
      self.owner.viewObj.ThrowHalfAngle = math.FInterpTo(self.owner.viewObj.ThrowHalfAngle, angle, deltaTime, 8)
    end
  end
end

function ScenePlayerThrowBuff:RecoverView()
  if self.SkillInfo.typedConfig.limit_pitch then
    self:GetController().PlayerCameraManager.ViewPitchMin = -89.9
    self:GetController().PlayerCameraManager.ViewPitchMax = 89.9
  end
  if self.SkillInfo.typedConfig.limit_yaw then
    self:GetController().PlayerCameraManager.ViewYawMin = 0
    self:GetController().PlayerCameraManager.ViewYawMax = 359.999
  end
end

function ScenePlayerThrowBuff:GetController()
  local ctrl = self.owner:GetUEController()
  if nil == ctrl then
    ctrl = UE4.UGameplayStatics.GetPlayerControllerFromID(self.owner.viewObj, 0)
  end
  return ctrl
end

function ScenePlayerThrowBuff:UpdateDirection()
  if self.owner and self.owner.viewObj then
    local LockedTarget = self.SkillInfo.ThrowInfo.AutoAimNPC
    if nil ~= LockedTarget and self.isFast then
      local targetLocarion = LockedTarget.viewObj:Abs_K2_GetActorLocation()
      self.Direction = UE4.UKismetMathLibrary.Normal(UE4.UKismetMathLibrary.Subtract_VectorVector(targetLocarion, self:GetStartPos()))
      self.FaceDirection = UE4.UKismetMathLibrary.Normal(UE4.UKismetMathLibrary.Subtract_VectorVector(targetLocarion, self.owner.viewObj:Abs_K2_GetActorLocation()))
    else
      local cameraRoatation = self:GetController().PlayerCameraManager:GetCameraRotation()
      self.Direction = UE4.UKismetMathLibrary.GetForwardVector(cameraRoatation)
      self.FaceDirection = self.Direction
    end
    if self.isFast then
      if nil ~= LockedTarget then
        local startPos = self:GetStartPos()
        local targetLocarion = LockedTarget.viewObj:Abs_K2_GetActorLocation()
        local distence = UE4.UKismetMathLibrary.Vector_Distance(startPos, targetLocarion)
        self.AngleOffset = -(distence - 300) / 500
      else
        local pitch = self:GetThrowAngle()
        self.AngleOffset = self.SkillInfo.FastThrowAngleOffset:GetFloatValue(pitch)
      end
    else
      local ballLua = self.SkillInfo and self.SkillInfo.BallLua
      local ThrowSession = ballLua and ballLua.ThrowSession
      local ballAct = ThrowSession and ThrowSession:GetThrowBallActConf()
      self.AngleOffset = -(ballAct and ballAct.ball_raise_angle or 3.5)
    end
  end
end

function ScenePlayerThrowBuff:TrySnycRotation()
  if NRCEnv:IsLocalMode() then
    return
  end
end

function ScenePlayerThrowBuff:CalculateVelocity()
  local PlayerCameraManager = self:GetController().PlayerCameraManager
  local RightVector = PlayerCameraManager:GetCameraRotation():GetRightVector()
  local Direction = UE4.UKismetMathLibrary.RotateAngleAxis(self.Direction, self.AngleOffset, RightVector)
  local pitch = self:GetThrowAngle()
  return Direction * self.Strength * self.SkillInfo.AimThrowSpeedOffset:GetFloatValue(pitch)
end

function ScenePlayerThrowBuff:DrawDebugTrajectory(DrawDebugType, DrawDebugTime)
  local StartPos = self:GetStartPos()
  local Velocity = self:CalculateVelocity()
  DrawDebugType = DrawDebugType or UE4.EDrawDebugTrace.ForOneFrame
  DrawDebugTime = DrawDebugTime or 1
  local OutHit, OutPathPositions, OutLastTraceDestination, bHit = UE4.UGameplayStatics.Abs_Blueprint_PredictProjectilePath_ByTraceChannel(self.owner.viewObj, nil, nil, nil, StartPos, Velocity, true, 5.0, UE4.ECollisionChannel.ECC_GameTraceChannel9, false, nil, DrawDebugType, DrawDebugTime, 100, 10, self.Gravity * -980)
  local TraceResult = {
    bHit = bHit,
    OutHit = OutHit,
    OutPathPositions = OutPathPositions,
    OutLastTraceDestination = OutLastTraceDestination
  }
  local totalLength = 0
  for i = 2, OutPathPositions:Length() do
    totalLength = totalLength + UE4.UKismetMathLibrary.Vector_Distance(OutPathPositions:Get(i), OutPathPositions:Get(i - 1))
  end
  UE4.UKismetSystemLibrary.PrintString(self.owner.viewObj, "\233\163\158\232\161\140\232\183\157\231\166\187\239\188\154" .. totalLength, true, false, UE4.FLinearColor(1, 0, 0.5, 1), UE4.UGameplayStatics.GetWorldDeltaSeconds(self.owner.viewObj))
  return TraceResult
end

function ScenePlayerThrowBuff:GetStartPos()
  local PlayerCameraManager = self:GetController().PlayerCameraManager
  local cameraLocation = PlayerCameraManager:Abs_GetCameraLocation()
  local playerlocation = self.owner.viewObj:Abs_K2_GetActorLocation()
  local Distance = UE4.UKismetMathLibrary.Vector_Distance(playerlocation, cameraLocation)
  local cameraForward = UE4.UKismetMathLibrary.GetForwardVector(PlayerCameraManager:GetCameraRotation())
  local CameraDelta = UE4.UKismetMathLibrary.Multiply_VectorFloat(cameraForward, Distance)
  return UE4.UKismetMathLibrary.Add_VectorVector(CameraDelta, cameraLocation)
end

function ScenePlayerThrowBuff:GetThrowAngle()
  local pitch = self:GetController().PlayerCameraManager:GetCameraRotation().Pitch
  if pitch > 180 then
    pitch = pitch - 360
  end
  return pitch
end

return ScenePlayerThrowBuff

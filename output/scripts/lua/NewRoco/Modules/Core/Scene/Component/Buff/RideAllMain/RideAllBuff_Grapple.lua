local Base = require("NewRoco.Modules.Core.Scene.Component.Buff.RideAllMain.RideAllBuff_SkillBase")
local StatType = require("NewRoco.Modules.Core.Scene.Component.Stat.StatType")
local AbilityEvent = require("NewRoco.Modules.Core.Scene.Component.Ability.AbilityEvent")
local PlayerModuleEvent = require("NewRoco.Modules.Core.PlayerModule.PlayerModuleEvent")
local RidePetEvent = require("NewRoco.Modules.Core.Scene.Component.RidePet.RidePetEvent")
local SceneUtils = require("NewRoco.Modules.Core.Scene.Common.SceneUtils")
local MainUIModuleEvent = require("NewRoco.Modules.System.MainUI.MainUIModuleEvent")
local RideAllBuff_Grapple = Base:Extend("RideAllBuff_Grapple")
local GrappleStatus = {
  None = -1,
  Start = 0,
  InAim = 1,
  WaitingMove = 2,
  CollisionWaitingMove = 3,
  InMoveing = 4,
  End = 5,
  Cancel = 6
}

function RideAllBuff_Grapple:OnBuffBegin(Owner, SkillConf)
  Base.OnBuffBegin(self, Owner, SkillConf, false)
  self:AnalyPropertyModify(SkillConf)
  self.quickGrappleAngle = tonumber(SkillConf.move_param_1) / 180 * math.pi
  self.rayMaxLength = tonumber(SkillConf.move_param_2)
  self.delayMoveTime = tonumber(SkillConf.move_param_3)
  self.moveSpeedCurve = _G.PlayerResourceManager:GetStaticResource(SkillConf.move_param_4)
  self.attenuationCoefficient = tonumber(SkillConf.move_param_5)
  self.collisionMaxAngle = tonumber(SkillConf.move_param_6) / 180 * math.pi
  self._endTime = tonumber(SkillConf.move_param_7)
  self.aimMaxAngle = tonumber(SkillConf.move_param_8)
  self.aimMinAngle = tonumber(SkillConf.move_param_9)
  self.curGrappleStatus = GrappleStatus.None
  self._curRunTime = 0
  self._longPressMinTime = 0.2
  self.isAttenuation = true
  self.owner:AddEventListener(self, PlayerModuleEvent.ON_AIM_JOYSTICK_RELEASED, self.OnAimJoystickReleased)
  self.owner:AddEventListener(self, MainUIModuleEvent.PCCancelChargeBtnClicked, self.OnCancel)
  self.CameraABP = self.owner:GetUEController().PlayerCameraManager:GetCameraAnimInstance()
  self.moveComp = self.RidePet.CharacterMovement
  self.fallingComp = self.RidePet.CharacterFallingMovement
  self.destinationCollisionEffect = "/Game/ArtRes/Effects/Particle/Scene/Pet/Ecology/NS_Sence_Ecology_HookLock_01.NS_Sence_Ecology_HookLock_01"
  self.destinationEffect = "/Game/ArtRes/Effects/Particle/Scene/Pet/Ecology/NS_Sence_Ecology_HookLock_02.NS_Sence_Ecology_HookLock_02"
  self.hookLockEffect = "/Game/ArtRes/Effects/Particle/Scene/Pet/Ecology/NS_Sence_Ecology_HookLock_03.NS_Sence_Ecology_HookLock_03"
  self.destinationCollisionEffectID = 0
  self.destinationEffectID = 0
  self.hookLockEffectID = 0
  self.curShowEffectID = 0
  local SendVitality = self:GetFinalStartCost()
  if SendVitality > self.owner.vitalityComponent:GetCurVitality() then
    SendVitality = self.owner.vitalityComponent:GetCurVitality()
  end
  self.owner:SendEvent(PlayerModuleEvent.ON_PRE_VITALITY_COST_INIT, SendVitality, self._endTime)
  self.hasRecovered = true
  self:StartCostVitality()
end

function RideAllBuff_Grapple:GetFinalStartCost()
  if not (self.owner and self.owner.vitalityComponent) or not self.SkillConf then
    Log.Error("Get Final Start Cost Failed!")
    return 0
  end
  return self.owner.vitalityComponent:GetVitalityCostRatio() * self.SkillConf.vitality_cost.start_cost
end

function RideAllBuff_Grapple:OnStartCostVitalityFinish(StartCostSuccess)
  if StartCostSuccess then
    self.curGrappleStatus = GrappleStatus.Start
    self.hasRecovered = false
  else
    self.owner:SendEvent(PlayerModuleEvent.ON_PRE_VITALITY_COST_END)
    self.curGrappleStatus = GrappleStatus.Cancel
    self:StartFail()
  end
end

function RideAllBuff_Grapple:OnCancel()
  if not self.hasRecovered and (self.curGrappleStatus == GrappleStatus.Start or self.curGrappleStatus == GrappleStatus.InAim) then
    self.owner.vitalityComponent:RecoverVitalityByValue(self:GetFinalStartCost())
  end
  self:StopActiveSKill()
  _G.NRCModuleManager:GetModule("MainUIModule"):DispatchEvent(MainUIModuleEvent.ChangePCCancelChargeBtnVisibility, false)
  self.curGrappleStatus = GrappleStatus.Cancel
end

function RideAllBuff_Grapple:OnBuffUpdate(deltaTime)
  if _G.AppMain and _G.AppMain.isEnterBackground then
    Log.Error("\227\128\144\233\146\169\233\148\129\230\138\128\232\131\189\227\128\145\229\136\135\229\144\142\229\143\176\239\188\140\229\143\145\233\128\129ON_PRE_VITALITY_COST_END\228\186\139\228\187\182\239\188\140\229\129\156\230\173\162\230\138\128\232\131\189")
    self.owner:SendEvent(PlayerModuleEvent.ON_PRE_VITALITY_COST_END)
    self:StopActiveSKill()
    return
  end
  if self.curGrappleStatus == GrappleStatus.Start then
    self._curRunTime = self._curRunTime + deltaTime
    if self._curRunTime >= self._longPressMinTime then
      self.CameraABP.RideGrapple = true
      self.curGrappleStatus = GrappleStatus.InAim
      self.owner:GetUEController().PlayerCameraManager.ViewPitchMin = self.aimMinAngle
      self.owner:GetUEController().PlayerCameraManager.ViewPitchMax = self.aimMaxAngle
      NRCModuleManager:DoCmd(MainUIModuleCmd.ShowFrontSight, true, nil, true)
      UE4.UNRCAudioManager.Get():PlaySound2DAuto(1117, "RideAllBuff_Grapple:InAim")
      if not UE4Helper.IsPCMode() then
        _G.NRCModuleManager:GetModule("MainUIModule"):DispatchEvent(MainUIModuleEvent.UI_SHOW_ABILITY_AIM_JOYSTICK, true)
      else
        _G.NRCModuleManager:GetModule("MainUIModule"):DispatchEvent(MainUIModuleEvent.ChangePCCancelChargeBtnVisibility, true)
      end
    end
  elseif self.curGrappleStatus == GrappleStatus.WaitingMove or self.curGrappleStatus == GrappleStatus.CollisionWaitingMove then
    self.waitTime = self.waitTime + deltaTime
    if self.waitTime >= self.delayMoveTime then
      self.curGrappleStatus = GrappleStatus.InMoveing
      self.RidePet.Mesh:GetAnimInstance().IsGrapple = true
      self.moveingTime = 0
      if self.RideComp.RideMoveType ~= ProtoEnum.SceneRideAllType.SRAT_SWIM then
        self.RidePet.CharacterMovement:SetMovementMode(3)
      else
        self.owner:SetSwimFxVisible(false, "GrappleBuff")
      end
      if not self.RidePet:GetActorHidden() then
        self.trailFxID = self.RidePet.RocoFX:PlayFx_Type_Setting2(self.RidePet.HookLockTrailFX, UE4.EFXAttachPointType.Pos, true, UE4.FTransform(), true)
      end
      self:OnRefreshRideallAbilityPlayerStatus(self.curGrappleStatus)
      self.deltaLength = nil
      self.lastPosition = nil
      local location = self.RidePet:Abs_K2_GetActorLocation()
      self.maxDelta = UE.UKismetMathLibrary.Subtract_VectorVector(self.endPos, location):Size()
      self.RidePet:AddEventListener(self, RidePetEvent.HANDLE_IMPACT, self.HandleImpact)
      self.RidePet.RocoAudio:PlayAudioToSelf(42300118)
      self.owner.abilityComponent:SendEvent(AbilityEvent.ON_BUFF_LOOP_BEGIN, self._abilityID)
    end
  elseif self.curGrappleStatus == GrappleStatus.InAim then
    local Rotation = self.RidePet:K2_GetActorRotation()
    Rotation.Yaw = self.owner:GetUEController().PlayerCameraManager:GetCameraRotation().Yaw
    local isAttenuation, deltaVec = self:GetGrappleDestination()
    if isAttenuation then
      if 0 ~= self.destinationCollisionEffectID then
        _G.NRCModuleManager:GetModule("MainUIModule"):DispatchEvent(MainUIModuleEvent.UI_UpdateFrontSight, false)
        self.RidePet.RocoFX:ShowHideFxByID(self.destinationCollisionEffectID, false)
      end
      self.curShowEffectID = 0
    else
      self:PlayDestinationCollisionFX(deltaVec)
    end
  elseif self.curGrappleStatus == GrappleStatus.InMoveing then
    self.moveingTime = self.moveingTime + deltaTime
    if self.moveingTime > self._endTime then
      self:StopActiveSKill()
    else
      local location = self.RidePet:Abs_K2_GetActorLocation()
      self:PlayHookLockFX()
      local delta = UE.UKismetMathLibrary.Subtract_VectorVector(self.endPos, location):Size()
      if self.deltaLength == nil then
        self.deltaLength = delta + 0.01
      end
      if self.lastPosition then
        local lastDir = UE.UKismetMathLibrary.Subtract_VectorVector(self.endPos, self.lastPosition)
        lastDir:Normalize()
        local curDir = UE.UKismetMathLibrary.Subtract_VectorVector(self.endPos, location)
        curDir:Normalize()
        local angle = math.max(math.min(lastDir.X * curDir.X + lastDir.Y * curDir.Y + lastDir.Z * curDir.Z, 1), -1)
        if angle < 0 then
          self:StopActiveSKill()
          return
        end
      end
      self.lastPosition = location
      if delta > self.deltaLength then
        self:StopActiveSKill()
      else
        self.deltaLength = delta
        local deltaLength = math.max(self.maxDelta - delta, 0)
        local radio = math.min(deltaLength / self.maxDelta, 1)
        local dir = UE.UKismetMathLibrary.Subtract_VectorVector(self.endPos, location)
        dir:Normalize()
        if self.moveSpeedCurve then
          local NewVelocity = self.moveSpeedCurve:GetFloatValue(radio)
          if nil ~= NewVelocity then
            if self.propertyModify[4] then
              if 0 == self.modifyMode then
                NewVelocity = NewVelocity + self.modifyValue
              elseif 1 == self.modifyMode then
                NewVelocity = NewVelocity + NewVelocity * self.modifyValue / 10000
              end
            end
            NewVelocity = self.isAttenuation and NewVelocity * self.attenuationCoefficient or NewVelocity
            NewVelocity = dir * NewVelocity
            self.moveComp:ApplyVelocity(UE.EApplyMovementStatType.ImpulseOverride, NewVelocity)
          else
            Log.Error("RideAllBuff_Grapple:OnBuffUpdate Velocity is nil from Curve")
          end
          self.RidePet.CharacterMovement:SetMovementMode(3)
          local maxLength = math.max(self.RidePet.capsuleComponent:GetScaledCapsuleHalfHeight(), self.RidePet.capsuleComponent:GetScaledCapsuleRadius()) + 10
          local receivabilityDeltaLength = not self.isAttenuation and maxLength or 1
          if delta <= receivabilityDeltaLength then
            self:StopActiveSKill()
          end
        else
          Log.Error("Speed Curve Load Failed")
          self:StopActiveSKill()
        end
      end
    end
  end
end

function RideAllBuff_Grapple:GetAimDir()
  local PlayerCameraManager = self:GetController().PlayerCameraManager
  local cameraRoatation = self:GetController().PlayerCameraManager:GetCameraRotation()
  local direction = UE4.UKismetMathLibrary.GetForwardVector(cameraRoatation)
  local rightVector = PlayerCameraManager:GetCameraRotation():GetRightVector()
  local direction = UE4.UKismetMathLibrary.RotateAngleAxis(direction, 0, rightVector)
  direction:Normalize()
  return direction
end

function RideAllBuff_Grapple:GetAimStartPos(location)
  local PlayerCameraManager = self:GetController().PlayerCameraManager
  local cameraLocation = PlayerCameraManager:Abs_GetCameraLocation()
  local Distence = UE4.UKismetMathLibrary.Vector_Distance2D(location, cameraLocation)
  local cameraForward = UE4.UKismetMathLibrary.GetForwardVector(PlayerCameraManager:GetCameraRotation())
  local CameraDelta = UE4.UKismetMathLibrary.Multiply_VectorFloat(cameraForward, Distence)
  return UE4.UKismetMathLibrary.Add_VectorVector(CameraDelta, cameraLocation)
end

function RideAllBuff_Grapple:StopActiveSKill()
  self.curGrappleStatus = GrappleStatus.End
  Base.StopActiveSKill(self)
end

function RideAllBuff_Grapple:OnRemotePlayerBuffBegin(Owner, SkillConf)
  Base.OnRemotePlayerBuffBegin(self, Owner, SkillConf, false)
  self.destinationCollisionEffectID = 0
  self.destinationEffectID = 0
  self.hookLockEffectID = 0
  self.trailFxID = 0
end

function RideAllBuff_Grapple:OnRemotePlayEffect(stage, target_pos)
  if UE.UObject.IsValid(self.RidePet) then
    local endPos = SceneUtils.ServerPos2ClientPos(target_pos, 100)
    if stage == GrappleStatus.WaitingMove then
      local location = self.RidePet:Abs_K2_GetActorLocation()
      self:PlayDestinationFX(UE.UKismetMathLibrary.Subtract_VectorVector(endPos, location))
      self:PlayHookLockFX(UE.UKismetMathLibrary.Subtract_VectorVector(endPos, location))
      self.RidePet.RocoAudio:PlayAudioToSelf(42300117)
    elseif stage == GrappleStatus.CollisionWaitingMove then
      local location = self.RidePet:Abs_K2_GetActorLocation()
      self:PlayDestinationCollisionFX(UE.UKismetMathLibrary.Subtract_VectorVector(endPos, location))
      self:PlayHookLockFX(UE.UKismetMathLibrary.Subtract_VectorVector(endPos, location))
      self.RidePet.RocoAudio:PlayAudioToSelf(42300117)
    elseif stage == GrappleStatus.InMoveing then
      if not self.RidePet:GetActorHidden() then
        self.trailFxID = self.RidePet.RocoFX:PlayFx_Type_Setting2(self.RidePet.HookLockTrailFX, UE4.EFXAttachPointType.Pos, true, UE4.FTransform(), true)
      end
      self.RidePet.RocoAudio:PlayAudioToSelf(42300118)
    end
  end
end

function RideAllBuff_Grapple:OnRemotePlayerBuffFinish(param)
  Base.OnRemotePlayerBuffFinish(self, param)
  if UE.UObject.IsValid(self.RidePet) then
    if UE.UObject.IsValid(self.RidePet.RocoFX) then
      if 0 ~= self.destinationCollisionEffectID then
        self.RidePet.RocoFX:StopFx(self.destinationCollisionEffectID)
      end
      if 0 ~= self.destinationEffectID then
        self.RidePet.RocoFX:StopFx(self.destinationEffectID)
      end
      if 0 ~= self.hookLockEffectID then
        self.RidePet.RocoFX:StopFx(self.hookLockEffectID)
      end
      if 0 ~= self.trailFxID then
        self.RidePet.RocoFX:StopFx(self.trailFxID)
      end
    end
    self.RidePet.RocoAudio:StopAudioToSelf(42300118, 0.2)
  end
end

function RideAllBuff_Grapple:OnPlayerStatusRefresh(status, value, opCode)
  if status == ProtoEnum.WorldPlayerStatusType.WPST_RIDEALL_ABILITY then
    local customParams = self.owner.statusComponent:GetCustomParams(ProtoEnum.WorldPlayerStatusType.WPST_RIDEALL_ABILITY)
    self:OnRemotePlayEffect(customParams.ride_skill_param.skill_stage, customParams.ride_skill_param.target_pos)
  end
end

function RideAllBuff_Grapple:PlayDestinationCollisionFX(deltaVec)
  local location = self.RidePet:K2_GetActorLocation()
  if 0 == self.curShowEffectID and 0 ~= self.destinationCollisionEffectID then
    self.RidePet.RocoFX:ShowHideFxByID(self.destinationCollisionEffectID, true)
    _G.NRCModuleManager:GetModule("MainUIModule"):DispatchEvent(MainUIModuleEvent.UI_UpdateFrontSight, true)
  end
  local fTransfom = UE4.FTransform(UE4.FQuat(), UE.UKismetMathLibrary.Add_VectorVector(location, deltaVec), UE4.FVector(1, 1, 1))
  if 0 == self.destinationCollisionEffectID then
    if not self.RidePet:GetActorHidden() then
      self.destinationCollisionEffectID = self.RidePet.RocoFX:PlayFx_Location(self.RidePet.HookLockDestinationCollisionFX, fTransfom)
    end
    _G.NRCModuleManager:GetModule("MainUIModule"):DispatchEvent(MainUIModuleEvent.UI_UpdateFrontSight, true)
  else
    self.RidePet.RocoFX:UpdateFXTransformByID(0, self.destinationCollisionEffectID, fTransfom)
  end
  self.curShowEffectID = self.destinationCollisionEffectID
end

function RideAllBuff_Grapple:PlayDestinationFX(deltaVec)
  local location = self.RidePet:K2_GetActorLocation()
  local fTransfom = UE4.FTransform(UE4.FQuat(), UE.UKismetMathLibrary.Add_VectorVector(location, deltaVec), UE4.FVector(1, 1, 1))
  if 0 == self.destinationEffectID then
    if not self.RidePet:GetActorHidden() then
      self.destinationEffectID = self.RidePet.RocoFX:PlayFx_Location(self.RidePet.HookLockDestinationFX, fTransfom)
    end
  else
    self.RidePet.RocoFX:UpdateFXTransformByID(0, self.destinationEffectID, fTransfom)
  end
  self.curShowEffectID = self.destinationEffectID
end

function RideAllBuff_Grapple:PlayHookLockFX(deltaVec)
  local location = self.RidePet:K2_GetActorLocation()
  local fTransfom = UE4.FTransform(UE4.FQuat(), location, UE4.FVector(1, 1, 1))
  if 0 == self.hookLockEffectID then
    if not self.RidePet:GetActorHidden() then
      self.hookLockEffectID = self.RidePet.RocoFX:PlayFx_Location(self.RidePet.HookLockFX, fTransfom)
      local fxSystemComponent = self.RidePet.RocoFX:GetFxSystemComponentById(self.hookLockEffectID)
      fxSystemComponent:SetVectorParameter("Target", UE.UKismetMathLibrary.Add_VectorVector(location, deltaVec))
    end
  else
    self.RidePet.RocoFX:UpdateFXTransformByID(0, self.hookLockEffectID, fTransfom)
  end
end

function RideAllBuff_Grapple:GetGrappleDestination()
  local startPos = UE4.FVector(0, 0, 0)
  local endPos = UE4.FVector(0, 0, 0)
  local dir = UE4.FVector(0, 0, 0)
  local location = self.RidePet:Abs_K2_GetActorLocation()
  if self.curGrappleStatus == GrappleStatus.InAim then
    startPos = self:GetAimStartPos(location)
    dir = self:GetAimDir()
  end
  local dirVector = UE.UKismetMathLibrary.Multiply_VectorFloat(dir, self.rayMaxLength)
  endPos = UE.UKismetMathLibrary.Add_VectorVector(startPos, dirVector)
  local ignoreActor = {
    self.RidePet,
    self.owner
  }
  local isAttenuation = true
  local Hit, Success = UE4.UKismetSystemLibrary.Abs_LineTraceSingle(_G.UE4Helper.GetCurrentWorld(), startPos, endPos, UE.ETraceTypeQuery.Water, false, ignoreActor)
  if Success then
    isAttenuation = false
    endPos = Hit.ImpactPoint
    local swimImmergeDepth = self.RidePet.CharacterSwimMovement:GetStartSwimImmergeDepth()
    endPos.Z = endPos.Z - swimImmergeDepth + self.RideComp.CapsuleHalfHeight
    return isAttenuation, UE.UKismetMathLibrary.Subtract_VectorVector(endPos, location)
  end
  Hit, Success = UE4.UKismetSystemLibrary.Abs_LineTraceSingle(_G.UE4Helper.GetCurrentWorld(), startPos, endPos, UE.ETraceTypeQuery.Visibility, false, ignoreActor)
  if Success then
    local hitActor = Hit.Actor
    local playerActor = hitActor and Hit.Actor:Cast(UE4.ARocoPlayerBase)
    self.collisionActor = nil
    if playerActor then
    else
      local sceneNpc = hitActor and hitActor.sceneCharacter
      if sceneNpc and sceneNpc.config and 1 == tonumber(sceneNpc.config.editor_name_1) then
      else
        isAttenuation = false
        endPos = Hit.ImpactPoint
      end
    end
  end
  return isAttenuation, UE.UKismetMathLibrary.Subtract_VectorVector(endPos, location)
end

function RideAllBuff_Grapple:OnAbilityReleased()
  if self.curGrappleStatus ~= GrappleStatus.Start and self.curGrappleStatus ~= GrappleStatus.InAim then
    return
  end
  self.owner:SendEvent(PlayerModuleEvent.ON_PRE_VITALITY_COST_BEGIN)
  local startPos = UE4.FVector(0, 0, 0)
  local endPos = UE4.FVector(0, 0, 0)
  local dir = UE4.FVector(0, 0, 0)
  local location = self.RidePet:Abs_K2_GetActorLocation()
  if self.curGrappleStatus == GrappleStatus.Start then
    startPos = location
    local vectorData = self.RidePet:GetActorForwardVector()
    vectorData.Z = 0
    vectorData:Normalize()
    vectorData.X = vectorData.X * math.cos(self.quickGrappleAngle)
    vectorData.Y = vectorData.Y * math.cos(self.quickGrappleAngle)
    vectorData.Z = math.sin(self.quickGrappleAngle)
    dir = vectorData
  elseif self.curGrappleStatus == GrappleStatus.InAim then
    NRCModuleManager:DoCmd(MainUIModuleCmd.ShowFrontSight, false, nil, true)
    startPos = self:GetAimStartPos(location)
    self.CameraABP.RideGrapple = false
    self.owner:GetUEController().PlayerCameraManager.ViewPitchMin = -89.9
    self.owner:GetUEController().PlayerCameraManager.ViewPitchMax = 89.9
    dir = self:GetAimDir()
  end
  self.waitTime = 0
  local dirVector = UE.UKismetMathLibrary.Multiply_VectorFloat(dir, self.rayMaxLength)
  endPos = UE.UKismetMathLibrary.Add_VectorVector(startPos, dirVector)
  local ignoreActor = {
    self.RidePet,
    self.owner
  }
  self.isAttenuation = true
  local Hit, Success = UE4.UKismetSystemLibrary.Abs_LineTraceSingle(_G.UE4Helper.GetCurrentWorld(), startPos, endPos, UE.ETraceTypeQuery.Water, false, ignoreActor)
  if Success then
    self.isAttenuation = false
    endPos = Hit.ImpactPoint
    local swimImmergeDepth = self.RidePet.CharacterSwimMovement:GetStartSwimImmergeDepth()
    endPos.Z = endPos.Z - swimImmergeDepth + self.RideComp.CapsuleHalfHeight
  else
    Hit, Success = UE4.UKismetSystemLibrary.Abs_LineTraceSingle(_G.UE4Helper.GetCurrentWorld(), startPos, endPos, UE.ETraceTypeQuery.Visibility, false, ignoreActor)
    if Success then
      local hitActor = Hit.Actor
      if hitActor then
        local playerActor = hitActor:Cast(UE4.ARocoPlayerBase)
        self.collisionActor = nil
        if playerActor then
        else
          local sceneNpc = hitActor and hitActor.sceneCharacter
          if sceneNpc and sceneNpc.config and 1 == tonumber(sceneNpc.config.editor_name_1) then
          else
            self.isAttenuation = false
            endPos = Hit.ImpactPoint
            self.collisionActor = hitActor
          end
        end
      end
    end
  end
  if self.isAttenuation then
    self.curGrappleStatus = GrappleStatus.WaitingMove
    self:PlayDestinationFX(UE.UKismetMathLibrary.Subtract_VectorVector(endPos, location))
  else
    self.curGrappleStatus = GrappleStatus.CollisionWaitingMove
    self:PlayDestinationCollisionFX(UE.UKismetMathLibrary.Subtract_VectorVector(endPos, location))
  end
  self.RidePet.RocoAudio:PlayAudioToSelf(42300117)
  self:PlayHookLockFX(UE.UKismetMathLibrary.Subtract_VectorVector(endPos, location))
  self.endPos = endPos
  self.owner.inputComponent:SetMoveEnable(self, false)
  self:OnRefreshRideallAbilityPlayerStatus(self.curGrappleStatus, self.endPos)
  self.RidePet.BP_RidePetRoleHpComponent:IsIgnoreDamageBuff(true)
  self.RidePet.BP_RidePetRoleHpComponent:IgnoreFallingDamage()
end

function RideAllBuff_Grapple:HandleImpact(Hit)
  local hitActor = Hit and Hit.Actor
  if not self.isAttenuation and hitActor == self.collisionActor then
    local location = self.RidePet:Abs_K2_GetActorLocation()
    local delta = UE.UKismetMathLibrary.Subtract_VectorVector(self.endPos, location):Size()
    local maxLength = math.max(self.RidePet.capsuleComponent:GetScaledCapsuleHalfHeight(), self.RidePet.capsuleComponent:GetScaledCapsuleRadius()) + 10
    self:StopActiveSKill()
    return
  end
  local ImpactNormal = Hit.ImpactNormal
  local location = self.RidePet:Abs_K2_GetActorLocation()
  local delta = UE.UKismetMathLibrary.Subtract_VectorVector(location, self.endPos)
  delta:Normalize()
  ImpactNormal:Normalize()
  local startPos = SceneUtils.ConvertRelativeToAbsolute(Hit.ImpactPoint)
  local dirVector = UE.UKismetMathLibrary.Multiply_VectorFloat(ImpactNormal, 100)
  endPos = UE.UKismetMathLibrary.Add_VectorVector(startPos, dirVector)
  local angle = math.acos(math.max(math.min(delta.X * ImpactNormal.X + delta.Y * ImpactNormal.Y + delta.Z * ImpactNormal.Z, 1), -1))
  local ang = 180 * angle / math.pi
  if angle < math.pi / 2 - self.collisionMaxAngle then
    self:StopActiveSKill()
  end
end

function RideAllBuff_Grapple:OnAimJoystickReleased(Success)
  if Success then
    self:OnAbilityReleased()
  else
    self:OnCancel()
  end
end

function RideAllBuff_Grapple:OnRidePetChangeMoveType()
  if self.RideComp.RideMoveType == ProtoEnum.SceneRideAllType.SRAT_SWIM then
    self:StopActiveSKill()
  end
end

function RideAllBuff_Grapple:OnMainAbilityReleased()
  if self.curGrappleStatus == GrappleStatus.Start then
    self:OnAbilityReleased()
  elseif self.curGrappleStatus == GrappleStatus.InAim and UE4Helper.IsPCMode() then
    self:OnAbilityReleased()
    _G.NRCModuleManager:GetModule("MainUIModule"):DispatchEvent(MainUIModuleEvent.ChangePCCancelChargeBtnVisibility, false)
  end
end

function RideAllBuff_Grapple:HandleRePress()
  return true
end

function RideAllBuff_Grapple:OnBuffFinish(param)
  self.RidePet:RemoveEventListener(self, RidePetEvent.HANDLE_IMPACT, self.HandleImpact)
  self.owner:RemoveEventListener(self, MainUIModuleEvent.PCCancelChargeBtnClicked, self.OnCancel)
  self.owner:RemoveEventListener(self, PlayerModuleEvent.ON_AIM_JOYSTICK_RELEASED, self.OnAimJoystickReleased)
  self.owner:SendEvent(PlayerModuleEvent.ON_PRE_VITALITY_COST_END)
  self.owner:SetSwimFxVisible(true, "GrappleBuff")
  self.RidePet.RocoAudio:StopAudioToSelf(42300118, 0.2)
  self.owner.abilityComponent:SendEvent(AbilityEvent.ON_BUFF_LOOP_END, self._abilityID)
  if self.curGrappleStatus ~= GrappleStatus.Cancel then
    self.RidePet.BP_RidePetRoleHpComponent:ResetStartFallingHeight()
  end
  self.RidePet.BP_RidePetRoleHpComponent:IsIgnoreDamageBuff(nil)
  if UE4Helper.IsPCMode() then
    _G.NRCModuleManager:GetModule("MainUIModule"):DispatchEvent(MainUIModuleEvent.ChangePCCancelChargeBtnVisibility, false)
  end
  self.RidePet.Mesh:GetAnimInstance().IsGrapple = false
  self.moveComp:ApplyVelocity(UE.EApplyMovementStatType.ImpulseOverride, FVectorZero)
  self.owner.inputComponent:SetMoveEnable(self, true)
  self.CameraABP.RideGrapple = false
  self.owner:GetUEController().PlayerCameraManager.ViewPitchMin = -89.9
  self.owner:GetUEController().PlayerCameraManager.ViewPitchMax = 89.9
  NRCModuleManager:DoCmd(MainUIModuleCmd.ShowFrontSight, false, nil, true)
  if self.trailFxID then
    self.RidePet.RocoFX:StopFx(self.trailFxID)
  end
  if 0 ~= self.destinationCollisionEffectID then
    self.RidePet.RocoFX:StopFx(self.destinationCollisionEffectID)
    local location = self.RidePet:K2_GetActorLocation()
    local fTransfom = UE4.FTransform(UE4.FQuat(), location, UE4.FVector(1, 1, 1))
    if not self.RidePet:GetActorHidden() then
      self.RidePet.RocoFX:PlayFx_Location(self.RidePet.HookLockParticleFX, fTransfom)
    end
  end
  if 0 ~= self.destinationEffectID then
    self.RidePet.RocoFX:StopFx(self.destinationEffectID)
  end
  if 0 ~= self.hookLockEffectID then
    self.RidePet.RocoFX:StopFx(self.hookLockEffectID)
  end
  Base.OnBuffFinish(self, param)
end

return RideAllBuff_Grapple

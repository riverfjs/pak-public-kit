local Base = require("NewRoco.Modules.Core.Scene.Component.ActorComponent")
local PlayerModuleEvent = require("NewRoco.Modules.Core.PlayerModule.PlayerModuleEvent")
local SceneUtils = require("NewRoco.Modules.Core.Scene.Common.SceneUtils")
local PlayerHomeInteractionComponent = Base:Extend("PlayerHomeInteratcionComponent")

function PlayerHomeInteractionComponent:Ctor()
end

function PlayerHomeInteractionComponent:Attach(owner)
  Base.Attach(self, owner)
  self._lieState = UE4.EPlayerLieState.None
  self._setTargetVector = UE4.FVector(0, 0, 0)
  self._setTargetRotator = UE4.FRotator(0, 0, 0)
  self.PlayerMeshTrans = UE4.FTransform(UE4.FRotator(0, -90, 0):ToQuat(), UE4.FVector(0, 0, -86.5))
  self:ClearCurveMove()
  if self.owner.isLocal then
  end
end

function PlayerHomeInteractionComponent:DeAttach()
  if self.owner.isLocal then
  end
  Base.DeAttach(self)
end

function PlayerHomeInteractionComponent:TryGetHomeABP()
  if UE.UObject.IsValid(self.player) then
    self.HomeABP = self.player.AnimComponent:GetAnimInstance("Home")
  end
  if UE.UObject.IsValid(self.HomeABP) then
    return true
  end
  return false
end

function PlayerHomeInteractionComponent:Update(deltaTime)
  if not UE.UObject.IsValid(self.player) then
    self.player = self.owner.viewObj
  end
  if not UE.UObject.IsValid(self.player) then
    return
  end
  if self.player.HomeInteractionState == UE4.EPlayerHomeState.Lie then
    if self.player.LieState ~= self._lieState and self:TryGetHomeABP() then
      self._lieState = self.player.LieState
      if self._lieState == UE4.EPlayerLieState.InLie then
        self:InitCurveMove(self._targetPositionStartLie, self._targetRotationStartLie, self.HomeABP.InLieCurveXY, self.HomeABP.InLieCurveZ, self.HomeABP.InLieCurveR)
      end
      if self._lieState == UE4.EPlayerLieState.LieTurn then
        self:InitCurveMove(self._targetPositionTurn, nil, self.HomeABP.TurnLieCurveXY)
      end
      if self._lieState == UE4.EPlayerLieState.EndLie then
        self:InitCurveMove(self._targetPositionEndLie, self._targetRotationEndLie, self.HomeABP.OutLieCurveXY, self.HomeABP.OutLieCurveZ, self.HomeABP.OutLieCurveR)
      end
    end
    if self._activeCurve then
      self:DoCurveMove(deltaTime)
    end
  end
  if self.player.HomeInteractionState ~= UE4.EPlayerHomeState.None then
    if not self.TickHUDTime then
      self.TickHUDTime = 0
    end
    self.TickHUDTime = self.TickHUDTime + deltaTime
    if self.TickHUDTime > 0.5 then
      self:UpdateHudComponent()
      self.TickHUDTime = 0
    end
  end
end

function PlayerHomeInteractionComponent:StartSit(Position, Direction, FloorHeight, Immediately, FadeType)
  Log.Debug("PlayerHomeInteractionComponent StartSit")
  FadeType = FadeType or ProtoEnum.SceneSitBlurType.SSBT_CLOSED
  if not self.owner or not UE.UObject.IsValid(self.player) then
    Log.Error("PlayerHomeInteractionComponent Player is nil")
    return
  end
  self.player.SitFadeType = FadeType
  if self.owner.isLocal then
    _G.FunctionBanManager:AddPlayerConditionType(Enum.PlayerConditionType.PCT_SITDOWN)
  end
  if not self.player:WasRecentlyRendered(0.1) then
    Log.Debug("PlayerHomeInteractionComponent StartSit Player is not rendered")
    Immediately = true
  end
  if self:TryGetHomeABP() then
    if self.player.HomeInteractionState ~= UE4.EPlayerHomeState.None then
      self.HomeABP:InterruptHomeInteraction()
    end
    self.HomeABP:ClearTransformFlag()
    if Immediately then
      self.HomeABP.SkipAnimIn = true
    end
  end
  self.player.HomeInteractionState = UE4.EPlayerHomeState.Sit
  local PlayerDistance = self.player:Abs_K2_GetActorLocation() - Position
  self:SetSitPosition(Position, Direction, FloorHeight)
  local RightDir = UE4.UKismetMathLibrary.GetRightVector(Direction:ToRotator())
  local LeftDistance = UE.UKismetMathLibrary.Dot_VectorVector(RightDir, PlayerDistance)
  if (LeftDistance > 50 or LeftDistance < -50) and self:TryGetHomeABP() then
    self.HomeABP:MarkLeftRightSit(LeftDistance > 50)
  end
  self.player.CharacterMovement:ConsumeInputVector()
  self.player.CharacterMovement:ConsumeInputVector()
  self.player.CharacterMovement:StopMovementImmediately()
  self.player:StopJumping()
  if self.owner.statusComponent then
    self.owner.statusComponent:RemoveStatus(Enum.WorldPlayerStatusType.WPST_MAGIC)
    self.owner.statusComponent:RemoveStatus(Enum.WorldPlayerStatusType.WPST_AIMTHROWING)
  end
  if self.owner.isLocal and self.owner.movementComponent then
    self.owner.movementComponent:ClearMoveInput()
  end
  self:SetCollisionEnable(false)
  self:AdjustHud()
end

function PlayerHomeInteractionComponent:EndSit(Position, Direction, FloorHeight)
  Log.Debug("PlayerHomeInteractionComponent EndSit")
  if not self.owner or not UE.UObject.IsValid(self.player) then
    Log.Error("PlayerHomeInteractionComponent Player is nil")
    return
  end
  if not self.player:WasRecentlyRendered(0.1) then
    Log.Debug("PlayerHomeInteractionComponent EndSit Player is not rendered")
    self:InterruptSit(Position, Direction, FloorHeight)
    return
  end
  if Position and Direction and FloorHeight then
    self:SetSitPosition(Position, Direction, FloorHeight)
  end
  if self:TryGetHomeABP() then
    self.HomeABP:EndHomeInteraction()
  end
end

function PlayerHomeInteractionComponent:InterruptSit(Position, Direction, FloorHeight)
  Log.Debug("PlayerHomeInteractionComponent InterruptSit")
  if not self.owner or not UE.UObject.IsValid(self.player) then
    Log.Error("PlayerHomeInteractionComponent Player is nil")
    return
  end
  if Position and Direction and FloorHeight then
    self:SetSitPosition(Position, Direction, FloorHeight)
  end
  if self:TryGetHomeABP() then
    self.HomeABP:InterruptHomeInteraction()
  end
end

function PlayerHomeInteractionComponent:StartLie(Position, Direction, Immediately)
  Log.Debug("PlayerHomeInteractionComponent StartLie", self.owner, Position)
  if not self.owner or not UE.UObject.IsValid(self.player) then
    Log.Error("PlayerHomeInteractionComponent Player is nil")
    return
  end
  if not self.player:WasRecentlyRendered(0.1) then
    Log.Debug("PlayerHomeInteractionComponent StartLie Player is not rendered")
    if self:TryGetHomeABP() then
      if self.player.HomeInteractionState ~= UE4.EPlayerHomeState.None then
        self.HomeABP:InterruptHomeInteraction()
      end
      self.HomeABP:ClearTransformFlag()
      self.HomeABP.SkipAnimIn = true
    end
    self.player:K2_SetActorRotation(UE4.UKismetMathLibrary.MakeRotFromX(Direction), false)
    local PositionLie = Position
    PositionLie.Z = PositionLie.Z + self.player:GetHalfHeight()
    self.player:Abs_K2_SetActorLocation_WithoutHit(PositionLie, false)
    self.player.HomeInteractionState = UE4.EPlayerHomeState.Lie
    self.player:StopJumping()
    self:SetCollisionEnable(false)
    self:AdjustHud()
    return
  end
  if self:TryGetHomeABP() then
    if self.player.HomeInteractionState ~= UE4.EPlayerHomeState.None then
      self.HomeABP:InterruptHomeInteraction()
    end
    self.HomeABP:ClearTransformFlag()
    if Immediately then
      self.HomeABP.SkipAnimIn = true
    end
  end
  self.player.HomeInteractionState = UE4.EPlayerHomeState.Lie
  self._targetPositionStartLie = Position
  self._targetPositionStartLie.Z = self._targetPositionStartLie.Z + self.player:GetHalfHeight()
  self._targetRotationStartLie = UE4.UKismetMathLibrary.MakeRotFromX(Direction)
  self.player.CharacterMovement:ConsumeInputVector()
  self.player.CharacterMovement:ConsumeInputVector()
  self.player.CharacterMovement:StopMovementImmediately()
  self.player:StopJumping()
  if self.owner.isLocal then
    _G.FunctionBanManager:AddPlayerConditionType(Enum.PlayerConditionType.PCT_SITDOWN)
    if self.owner.movementComponent then
      self.owner.movementComponent:ClearMoveInput()
    end
  end
  self:SetCollisionEnable(false)
  self:AdjustHud()
end

function PlayerHomeInteractionComponent:EndLie(EndPosition, Direction)
  Log.Debug("PlayerHomeInteractionComponent EndLie", self.owner)
  if not self.owner or not UE.UObject.IsValid(self.player) then
    Log.Error("PlayerHomeInteractionComponent Player is nil")
    return
  end
  local PositionEndLie = EndPosition
  PositionEndLie.Z = PositionEndLie.Z + self.player:GetHalfHeight()
  if not self.player:WasRecentlyRendered(0.1) then
    Log.Debug("PlayerHomeInteractionComponent EndLie Player is not rendered")
    self:InterruptLie(PositionEndLie, Direction)
    return
  end
  self._targetPositionEndLie = PositionEndLie
  self._targetRotationEndLie = UE4.UKismetMathLibrary.MakeRotFromX(Direction)
  if self:TryGetHomeABP() then
    self.HomeABP:EndHomeInteraction()
  end
end

function PlayerHomeInteractionComponent:InterruptLie(EndPosition, Direction)
  Log.Debug("PlayerHomeInteractionComponent InterruptLie")
  if not self.owner or not UE.UObject.IsValid(self.player) then
    Log.Error("PlayerHomeInteractionComponent Player is nil")
    return
  end
  if self:TryGetHomeABP() then
    self.HomeABP:InterruptHomeInteraction()
  end
end

function PlayerHomeInteractionComponent:ChangeLiePosition(NewPosition)
  Log.Debug("PlayerHomeInteractionComponent ChangeLiePosition")
  if not self.owner or not UE.UObject.IsValid(self.player) then
    Log.Error("PlayerHomeInteractionComponent Player is nil")
    return
  end
  if not self.player:WasRecentlyRendered(0.1) then
    Log.Debug("PlayerHomeInteractionComponent ChangeLiePosition Player is not rendered")
    self:ClearCurveMove()
    local PositionChangeLie = NewPosition
    PositionChangeLie.Z = PositionChangeLie.Z + self.player:GetHalfHeight()
    self.player:Abs_K2_SetActorLocation_WithoutHit(PositionChangeLie, false)
    return
  end
  self._targetPositionTurn = NewPosition
  local PlayerDistance = NewPosition - self.player:Abs_K2_GetActorLocation()
  local RightDir = self.player:GetActorRightVector()
  if self:TryGetHomeABP() then
    self.HomeABP:MarkLeftRightLie(UE.UKismetMathLibrary.Dot_VectorVector(RightDir, PlayerDistance) < 0)
  end
end

function PlayerHomeInteractionComponent:OnHomeAnimEnd()
  if self.owner.isLocal then
    _G.FunctionBanManager:RemovePlayerConditionType(Enum.PlayerConditionType.PCT_SITDOWN)
    self.owner:ForceSendMoveReq()
  end
  self:SetCollisionEnable(true)
  self.player.HomeInteractionState = UE4.EPlayerHomeState.None
  self._targetPositionStartLie = nil
  self._targetPositionEndLie = nil
  self._targetPositionTurn = nil
  self._targetRotationStartLie = nil
  self._targetRotationEndLie = nil
  self:ClearCurveMove()
  self:RestoreHud()
end

function PlayerHomeInteractionComponent:SetSitPosition(Position, Direction, FloorHeight)
  if self.player.HomeInteractionState == UE4.EPlayerHomeState.Sit then
    local TargetLocation = Position + Direction * 50
    TargetLocation.Z = TargetLocation.Z - FloorHeight + self.owner:GetScaledHalfHeight()
    local NeedChange = UE.UKismetMathLibrary.Vector_Distance(TargetLocation, self.player:Abs_K2_GetActorLocation()) > 1
    if NeedChange then
      self.player:Abs_K2_SetActorLocation_WithoutHit(TargetLocation)
    end
  end
  self.player.HomeInteractionTransform.Translation = Position
  self.player:K2_SetActorRotation(Direction:ToRotator(), false)
  self.player.HomeInteractionHeight = FloorHeight
end

function PlayerHomeInteractionComponent:ClearCurveMove()
  self._activeTargetPostion = nil
  self._activeTargetRotation = nil
  self._activePositionCurveXY = nil
  self._activePositionCurveZ = nil
  self._lastAlphaZ = 0
  self._activeRotationCurve = nil
  self._activeOriginPostion = nil
  self._activeOriginRotation = nil
  self._maxPositionCurveXYTime = 0
  self._maxPositionCurveZTime = 0
  self._maxRotationCurveTime = 0
  self._setTargetVector:Set(0, 0, 0)
  self._setTargetRotator.Yaw = 0
  self._activeTime = 0
  self._activeCurve = false
end

function PlayerHomeInteractionComponent:InitCurveMove(TargetPostion, TargetRotation, PositionCurveXY, PositionCurveZ, RotationCurve)
  if self._activeCurve then
    self:InterruptCurveMove()
  end
  self._activeTargetPostion = TargetPostion
  self._activeTargetRotation = TargetRotation
  self._activePositionCurveXY = PositionCurveXY
  self._activePositionCurveZ = PositionCurveZ
  self._activeRotationCurve = RotationCurve
  local _min
  if self._activePositionCurveXY then
    _min, self._maxPositionCurveXYTime = self._activePositionCurveXY:GetTimeRange()
  end
  if self._activePositionCurveZ then
    _min, self._maxPositionCurveZTime = self._activePositionCurveZ:GetTimeRange()
  end
  if self._activeRotationCurve then
    _min, self._maxRotationCurveTime = self._activeRotationCurve:GetTimeRange()
  end
  self._activeOriginPostion = self.player:Abs_K2_GetActorLocation()
  self._activeOriginRotation = self.player:K2_GetActorRotation()
  self._activeTime = 0
  self._activeCurve = true
  self._setTargetVector:Set(self._activeOriginPostion.X, self._activeOriginPostion.Y, self._activeOriginPostion.Z)
end

function PlayerHomeInteractionComponent:DoCurveMove(deltaTime)
  if self.player and self._activeCurve then
    self._activeTime = self._activeTime + deltaTime
    local PositionChanged = false
    if self._activeTargetPostion == nil then
      self._activePositionCurveXY = nil
      self._activePositionCurveZ = nil
    end
    if nil == self._activeTargetRotation then
      self._activeRotationCurve = nil
    end
    if self._activePositionCurveXY then
      local alpha = self._activePositionCurveXY:GetFloatValue(self._activeTime)
      if alpha <= 0 then
        self._setTargetVector.X = self._activeOriginPostion.X
        self._setTargetVector.Y = self._activeOriginPostion.Y
      elseif alpha >= 1 then
        self._setTargetVector.X = self._activeTargetPostion.X
        self._setTargetVector.Y = self._activeTargetPostion.Y
      else
        self._setTargetVector.X = (self._activeTargetPostion.X - self._activeOriginPostion.X) * alpha + self._activeOriginPostion.X
        self._setTargetVector.Y = (self._activeTargetPostion.Y - self._activeOriginPostion.Y) * alpha + self._activeOriginPostion.Y
      end
      PositionChanged = true
      if self._activeTime > self._maxPositionCurveXYTime then
        self._activePositionCurveXY = nil
      end
    end
    if self._activePositionCurveZ then
      local alpha = self._activePositionCurveZ:GetFloatValue(self._activeTime)
      local OverZ = -5
      if self._activeOriginPostion.Z > self._activeTargetPostion.Z then
        OverZ = self._activeOriginPostion.Z - self._activeTargetPostion.Z + 5
      end
      if alpha <= 0 then
        self._setTargetVector.Z = self._activeOriginPostion.Z
      elseif alpha > self._lastAlphaZ then
        self._setTargetVector.Z = (self._activeTargetPostion.Z + OverZ - self._activeOriginPostion.Z) * alpha / 2 + self._activeOriginPostion.Z
      else
        self._setTargetVector.Z = OverZ * (alpha - 1) + self._activeTargetPostion.Z
      end
      PositionChanged = true
      self._lastAlphaZ = alpha
      if self._activeTime > self._maxPositionCurveZTime then
        self._activePositionCurveZ = nil
      end
    end
    if PositionChanged then
      self.player:Abs_K2_SetActorLocation_WithoutHit(self._setTargetVector, false)
    end
    if self._activeRotationCurve then
      local alpha = self._activeRotationCurve:GetFloatValue(self._activeTime)
      if alpha <= 0 then
        self._setTargetRotator.Yaw = self._activeOriginRotation.Yaw
      elseif alpha >= 1 then
        self._setTargetRotator.Yaw = self._activeTargetRotation.Yaw
      else
        self._setTargetRotator = UE4.UKismetMathLibrary.RLerp(self._activeOriginRotation, self._activeTargetRotation, alpha, true)
      end
      self.player:K2_SetActorRotation(self._setTargetRotator, false)
      if self._activeTime > self._maxRotationCurveTime then
        self._activeRotationCurve = nil
      end
    end
    if not self._activePositionCurveXY and not self._activePositionCurveZ and not self._activeRotationCurve then
      self:ClearCurveMove()
    end
  end
end

function PlayerHomeInteractionComponent:InterruptCurveMove()
  local PositionChanged = false
  if self._activePositionCurveXY then
    self._setTargetVector.X = self._activeTargetPostion.X
    self._setTargetVector.Y = self._activeTargetPostion.Y
    PositionChanged = true
  end
  if self._activePositionCurveZ then
    self._setTargetVector.Z = self._activeTargetPostion.Z
    PositionChanged = true
  end
  if PositionChanged then
    self.player:Abs_K2_SetActorLocation_WithoutHit(self._setTargetVector, false)
  end
  if self._activeRotationCurve then
    self._setTargetRotator.Yaw = self._activeTargetRotation.Yaw
    self.player:K2_SetActorRotation(self._setTargetRotator, false)
  end
  self:ClearCurveMove()
end

function PlayerHomeInteractionComponent:SetCollisionEnable(Enable)
  self.owner:SetCollisionDisable(not Enable)
  if not self.owner.isLocal then
    if UE.UObject.IsValid(self.player) and self.player.Mesh then
      self.player.Mesh:K2_SetRelativeTransform(self.PlayerMeshTrans, false, nil, false)
    end
    if UE.UObject.IsValid(self.player) then
      self.player:SetNetRole(Enable and UE4.ENetRole.ROLE_SimulatedProxy or UE4.ENetRole.ROLE_NONE)
      self.player.CharacterMovement.bForceClientNetMode = Enable
    end
  end
end

function PlayerHomeInteractionComponent:AdjustHud()
  if not UE.UObject.IsValid(self.player) or not FriendModuleCmd then
    return
  end
  _G.NRCModuleManager:DoCmd(_G.FriendModuleCmd.OnCmdStartOverrideAttachment, self.player)
end

function PlayerHomeInteractionComponent:RestoreHud()
  if not UE.UObject.IsValid(self.player) or not FriendModuleCmd then
    return
  end
  _G.NRCModuleManager:DoCmd(_G.FriendModuleCmd.OnCmdStopOverrideAttachment, self.player)
  self:UpdateHudComponent()
end

function PlayerHomeInteractionComponent:UpdateHudComponent()
  if not UE.UObject.IsValid(self.player) then
    return
  end
  local InHomeState = self.player.HomeInteractionState ~= UE4.EPlayerHomeState.None
  local hudComponent = self.owner.hudComponent
  if self.owner.isLocal then
    hudComponent = self.owner.LocalPlayerHUDComponent
  end
  if hudComponent then
    if InHomeState then
      hudComponent:AdjustHudAfterDoubleRiding()
    else
      hudComponent:RestoreHudAfterDoubleRiding()
    end
  end
end

return PlayerHomeInteractionComponent

local Base = require("NewRoco.Modules.Core.Scene.Component.Movement.MovementComponentBase")
local SceneUtils = require("NewRoco.Modules.Core.Scene.Common.SceneUtils")
local PlayerModuleEvent = require("NewRoco.Modules.Core.PlayerModule.PlayerModuleEvent")
local MAX_DISCARD_TIME_OF_MOVE_DATA = 1000
local MAX_NUM_OF_MOVE_DATA = 30
local ReplicateMovementComponent = Base:Extend("ReplicateMovementComponent")

function ReplicateMovementComponent:Ctor()
  Base.Ctor(self)
  self.MainMoveQueue = _G.Queue(2 * MAX_NUM_OF_MOVE_DATA)
  self.RideMoveQueue = _G.Queue(2 * MAX_NUM_OF_MOVE_DATA)
end

function ReplicateMovementComponent:Attach(owner)
  Base.Attach(self, owner)
  self.owner:AddEventListener(self, PlayerModuleEvent.ON_PLAYER_STATUS_RECOVER_FINISH, self.OnPlayerStatusRecoverFinish)
  self.owner:AddEventListener(self, PlayerModuleEvent.ON_PLAYER_RIDING_ACTUALLY, self.OnPlayerRidingActually)
  self.owner:AddEventListener(self, PlayerModuleEvent.ON_PLAYER_RIDING_FAILED, self.OnPlayerRidingFailed)
  if self.owner.serverData and self.owner.serverData.move_info then
    Log.Debug("[DebugMove3P]ReplicateMovementComponent:Attach, init cachedMoveData with serverData", self.owner.serverData.base.name)
    local move_info = self.owner.serverData.move_info.move_info
    local moveData = _G.ProtoMessage:newSpaceAct_ClientMove()
    moveData.time_stamp = _G.ZoneServer:GetServerTime()
    moveData.to_pos = move_info.to_pos
    moveData.to_rot = move_info.to_rot
    moveData.speed = move_info.speed
    moveData.acceleration = move_info.acceleration
    moveData.move_mode = move_info.move_mode
    moveData.custom_mode = move_info.custom_mode
    moveData.stop_move = move_info.stop_move
    moveData.ctrl_rot = move_info.ctrl_rot
    moveData.ride_move = move_info.ride_move
    self:EnqueueMoveData(moveData)
  end
end

function ReplicateMovementComponent:DeAttach()
  Base.DeAttach(self)
  self.owner:RemoveEventListener(self, PlayerModuleEvent.ON_PLAYER_STATUS_RECOVER_FINISH, self.OnPlayerStatusRecoverFinish)
  self.owner:RemoveEventListener(self, PlayerModuleEvent.ON_PLAYER_RIDING_ACTUALLY, self.OnPlayerRidingActually)
  self.owner:RemoveEventListener(self, PlayerModuleEvent.ON_PLAYER_RIDING_FAILED, self.OnPlayerRidingFailed)
end

function ReplicateMovementComponent:HasRemainingMoveData()
  return self.MainMoveQueue:Size() > 0 or self.RideMoveQueue:Size() > 0
end

function ReplicateMovementComponent:IsRideMoveData(moveData)
  if moveData and moveData.ride_move then
    return true
  end
  return false
end

function ReplicateMovementComponent:EnqueueMoveData(moveData)
  if moveData then
    if self:IsRideMoveData(moveData) then
      self.RideMoveQueue:Enqueue(moveData)
    else
      self.MainMoveQueue:Enqueue(moveData)
    end
  end
end

function ReplicateMovementComponent:PushToNativeMovementComponent(moveData, nativeMoveComponent)
  if not moveData or not nativeMoveComponent then
    return
  end
  local targetPos = SceneUtils.ServerPos2PlayerPos(moveData.to_pos)
  local targetRot = SceneUtils.ServerPos2ClientRotator(moveData.to_rot)
  self.ctrlRot = SceneUtils.ServerPos2ClientRotator(moveData.ctrl_rot)
  local velocity = SceneUtils.ServerPos2ClientPos(moveData.speed)
  local acceleration = SceneUtils.ServerPos2ClientPos(moveData.acceleration)
  local rideMove = self:IsRideMoveData(moveData)
  local moveMode = moveData.move_mode or 0
  local customMode = moveData.custom_mode or 0
  local timeStamp = moveData.time_stamp
  local matePos, mateRot, mateMoveMode
  if moveData.mate_point then
    matePos = SceneUtils.ServerPos2PlayerPos(moveData.mate_point.pos)
    mateRot = SceneUtils.ServerPos2ClientRotator(moveData.mate_point.dir)
    mateMoveMode = moveData.mate_move_mode or 1
  end
  if _G.GlobalConfig.bDebugMoveLog then
    local EnableReplicateMove = false
    if rideMove then
      EnableReplicateMove = nativeMoveComponent.bReplicateMode
    else
      EnableReplicateMove = nativeMoveComponent.EnableReplicateMove
    end
    local bTickEnable = nativeMoveComponent:IsComponentTickEnabled()
    local ownerUin = self.owner:GetLogicId()
    Log.DebugFormat("[DebugMove3P]PushToNativeMovementComponent#0:(%d),RideMove(%d),MainQueue(%d),RideQueue(%d),EnableReplicateMove(%d),bTickEnable(%d)", ownerUin, rideMove and 1 or 0, self.MainMoveQueue:Size(), self.RideMoveQueue:Size(), EnableReplicateMove and 1 or 0, bTickEnable and 1 or 0)
    Log.DebugFormat("[DebugMove3P]PushToNativeMovementComponent#1:(%d),Location(%s),Rotation(%s),MovementMode(%d),CustomMode(%d),LinearVelocity(%s),TimeStamp(%d),GFrameNumber(%d)", ownerUin, targetPos, targetRot, moveMode, customMode, velocity, timeStamp, UE4.UNRCStatics.GetCurGFrameNumber())
    if moveData.mate_point then
      Log.DebugFormat("[DebugMove3P]PushToNativeMovementComponent#2:(%d),MatePos(%s),MateRot(%s),MateMoveMode(%d)", ownerUin, matePos, mateRot, mateMoveMode)
    end
  end
  nativeMoveComponent:ReplicateMoveData(targetPos, targetRot, moveMode, customMode, velocity, acceleration, timeStamp, matePos, mateRot, mateMoveMode)
  self.owner.module:DispatchEvent(PlayerModuleEvent.ON_RECEIVE_MOVE_DATA, moveData)
end

function ReplicateMovementComponent:Update(deltaTime)
  local Owner = self.owner
  if Owner and Owner.serverData and self:HasRemainingMoveData() then
    local bLoadingRidePet = Owner:IsLoadingRidePet()
    local bStatusRecovering = Owner:IsStatusRecovering()
    local bInStartTransforming = Owner:IsInStartTransforming()
    local bInEndTransforming = Owner:IsInEndTransforming()
    if bLoadingRidePet or bStatusRecovering or bInStartTransforming or bInEndTransforming then
      if _G.GlobalConfig.bDebugMoveLog then
        Log.Debug("[DebugMove3P]ReplicateMovementComponent skip Replicate,LoadingRidePet=", bLoadingRidePet, ",StatusRecovering=", bStatusRecovering, ",MainMoveQueue.Size=", self.MainMoveQueue:Size(), ",RideMoveQueue.Size=", self.RideMoveQueue:Size(), self.owner.serverData.base.name)
      end
      return
    end
    self:PushCurrentMoveData()
  end
end

function ReplicateMovementComponent:PushCurrentMoveData()
  local nativeMovementComponent, bInReallyRide = self:GetActiveMovement()
  if not nativeMovementComponent then
    Log.Debug("[DebugMove3P]ReplicateMovementComponent: TickMoveData can not find nativeMovementComponent!", self.owner.serverData.base.name)
    return
  end
  if bInReallyRide then
    while self.RideMoveQueue:Size() > 0 do
      local moveData = self.RideMoveQueue:Dequeue()
      self.lastRideMoveData = moveData
      self:PushToNativeMovementComponent(moveData, nativeMovementComponent)
    end
  else
    while self.MainMoveQueue:Size() > 0 do
      local moveData = self.MainMoveQueue:Dequeue()
      self.lastMainMoveData = moveData
      self:PushToNativeMovementComponent(moveData, nativeMovementComponent)
    end
  end
end

function ReplicateMovementComponent:IsInRideStatus()
  if self.owner.statusComponent:HasStatus(Enum.WorldPlayerStatusType.WPST_RIDEALL) then
    return true
  end
  return false
end

function ReplicateMovementComponent:IsInReallyRide()
  if self:IsInRideStatus() and self.owner.viewObj.BP_RideComponent and self.owner.viewObj.BP_RideComponent.RidePet then
    return true
  end
  return false
end

function ReplicateMovementComponent:GetActiveMovement()
  if not self.owner.viewObj then
    return nil, false
  end
  local nativeMovementComponent = self.owner.viewObj.CharacterMovement
  local bRiding = false
  if self:IsInReallyRide() then
    nativeMovementComponent = self.owner.viewObj.BP_RideComponent.RidePet.CharacterMovement
    bRiding = true
  end
  return nativeMovementComponent, bRiding
end

function ReplicateMovementComponent:GetRidePet()
  if self:IsInRideStatus() and self.owner.viewObj.BP_RideComponent and self.owner.viewObj.BP_RideComponent.RidePet then
    return self.owner.viewObj.BP_RideComponent.RidePet
  end
  return nil
end

function ReplicateMovementComponent:SetEnableReplicateMove(isEnable)
  Log.Debug("[DebugMove3P]ReplicateMovementComponent:SetEnableReplicateMove", self.owner.serverData.base.name, isEnable)
  local nativeMovementComponent = self.viewObj.CharacterMovement
  if nativeMovementComponent then
    nativeMovementComponent.EnableReplicateMove = isEnable
  end
end

function ReplicateMovementComponent:OnPlayerStatusRecoverFinish()
  Log.Debug("[DebugMove3P]ReplicateMovementComponent:OnPlayerStatusRecoverFinish", self.owner.serverData.base.name, self:IsInRideStatus(), ",GFrameNumber=", UE4.UNRCStatics.GetCurGFrameNumber())
  if not self:IsInRideStatus() then
    local Owner = self.owner
    Owner:CheckPlayerInSeat()
    Owner:CheckPlayerInBox()
  end
end

function ReplicateMovementComponent:OnPlayerRidingActually(bRide)
  Log.Debug("[DebugMove3P]ReplicateMovementComponent:OnPlayerRidingActually", bRide, self.owner.serverData.base.name, ",GFrameNumber=", UE4.UNRCStatics.GetCurGFrameNumber())
  if bRide then
    local RidePet = self:GetRidePet()
    if RidePet then
      RidePet:CacheMeshOffset()
    end
    self.owner.viewObj.CharacterMovement:ClearAllMoveData()
    self.MainMoveQueue:Clear()
    self.lastMainMoveData = nil
  else
    self.RideMoveQueue:Clear()
    local RidePet = self:GetRidePet()
    if RidePet and RidePet.CharacterMovement then
      RidePet.CharacterMovement:ClearAllMoveData()
    end
    self.RideMoveQueue:Clear()
    self.lastRideMoveData = nil
  end
end

function ReplicateMovementComponent:OnPlayerRidingFailed()
  Log.Debug("[DebugMove3P]ReplicateMovementComponent:OnPlayerRidingFailed", self.owner.serverData.base.name, ",GFrameNumber=", UE4.UNRCStatics.GetCurGFrameNumber())
  self.RideMoveQueue:Clear()
  self.lastRideMoveData = nil
end

function ReplicateMovementComponent:OnReceiveMoveData(moveData)
  if moveData then
    if self.MainMoveQueue:Size() > MAX_NUM_OF_MOVE_DATA or self.RideMoveQueue:Size() > MAX_NUM_OF_MOVE_DATA then
      Log.Error("[DebugMove3P]ReplicateMovementComponent:OnReceiveMoveData, too many move data, RawMoveQueueSize=", self.MainMoveQueue:Size(), ",RideMoveQueueSize=", self.RideMoveQueue:Size(), self.owner.serverData.base.name)
      self.MainMoveQueue:Clear()
      self.RideMoveQueue:Clear()
      self.lastMainMoveData = nil
      self.lastRideMoveData = nil
    end
    local FirstMoveData
    local MaxDeltaTime = 0
    if self.RideMoveQueue:Size() > 0 then
      FirstMoveData = self.RideMoveQueue:First()
      MaxDeltaTime = FirstMoveData.time_stamp - _G.ZoneServer:GetServerTime()
      if MaxDeltaTime > MAX_DISCARD_TIME_OF_MOVE_DATA then
        Log.Error("[DebugMove3P]ReplicateMovementComponent:OnReceiveMoveData, too old ride move data, RideMoveQueueSize=", self.RideMoveQueue:Size(), self.owner.serverData.base.name)
        self.RideMoveQueue:Clear()
        self.lastRideMoveData = nil
      end
    end
    if self.MainMoveQueue:Size() > 0 then
      FirstMoveData = self.MainMoveQueue:First()
      MaxDeltaTime = FirstMoveData.time_stamp - _G.ZoneServer:GetServerTime()
      if MaxDeltaTime > MAX_DISCARD_TIME_OF_MOVE_DATA then
        Log.Error("[DebugMove3P]ReplicateMovementComponent:OnReceiveMoveData, too old raw move data, RawMoveQueueSize=", self.MainMoveQueue:Size(), self.owner.serverData.base.name)
        self.MainMoveQueue:Clear()
        self.lastMainMoveData = nil
      end
    end
    self:EnqueueMoveData(moveData)
    if _G.GlobalConfig.bDebugMoveLog then
      local Lag = _G.ZoneServer:GetServerTime() - moveData.time_stamp
      local RTT = _G.ZoneServer:GetTConndRTT()
      local bRideMove = moveData.ride_move
      local ownerUin = self.owner:GetLogicId()
      Log.DebugFormat("[DebugMove3P]ReplicateMovementComponent:OnReceiveMoveData:(%d),RideMove(%d),MainQueue(%d),RideQueue(%d),MovementMode(%d),CustomMode(%d),TimeStamp(%d),Lag(%d),RTT(%d),GFrameNumber(%d)", ownerUin, bRideMove and 1 or 0, self.MainMoveQueue:Size(), self.RideMoveQueue:Size(), moveData.move_mode, moveData.custom_mode, moveData.time_stamp, Lag, RTT, UE4.UNRCStatics.GetCurGFrameNumber())
    end
  end
end

function ReplicateMovementComponent:OnApplyPlayerStatus(status, subStatus, opCode)
  if status ~= Enum.WorldPlayerStatusType.WPST_MANTLE then
    return
  end
  Log.Debug("[DebugMove3P]ReplicateMovementComponent:OnApplyPlayerStatus", status, subStatus, opCode, self.owner.serverData.base.name)
  if self.owner and self.owner.viewObj then
    self.owner.viewObj:SyncMantle(subStatus - 1)
  end
end

return ReplicateMovementComponent

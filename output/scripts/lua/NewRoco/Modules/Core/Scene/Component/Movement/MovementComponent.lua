local Base = require("NewRoco.Modules.Core.Scene.Component.Movement.MovementComponentBase")
local SceneUtils = require("NewRoco.Modules.Core.Scene.Common.SceneUtils")
local PlayerModuleEvent = require("NewRoco.Modules.Core.PlayerModule.PlayerModuleEvent")
local FVector2DUtils = require("NewRoco.Utils.FVector2DUtils")
local StatType = require("NewRoco.Modules.Core.Scene.Component.Stat.StatType")
local SyncNpcActionComponent = require("NewRoco.Modules.Core.Scene.Component.Sync.SyncNpcActionComponent")
local MovementComponent = Base:Extend("MovementComponent")
local MAX_VEL_ANG_CHANGE = 45
local MAX_VEL_ANG_CHANGE_DOT = math.cos(math.pi / 6)
local MAX_DIST_CHANGE = 1500
local CachePos1 = table.new(8, 0)
local CachePos2 = table.new(8, 0)
local CachePosTime1 = table.new(8, 0)
local CachePosTime2 = table.new(8, 0)
local CurrentCachePos = CachePos1
local CurrentCachePosTime = CachePosTime1
local PositionPool = table.new(16, 0)
local MoveSegmentPool = table.new(16, 0)

local function SwapCachePosList()
  if CurrentCachePos == CachePos1 then
    CurrentCachePos = CachePos2
  else
    CurrentCachePos = CachePos1
  end
  if CurrentCachePosTime == CachePosTime1 then
    CurrentCachePosTime = CachePosTime2
  else
    CurrentCachePosTime = CachePosTime1
  end
  for i = #CurrentCachePos, 1, -1 do
    local Pos = table.remove(CurrentCachePos, i)
    table.insert(PositionPool, Pos)
  end
  table.reset(CurrentCachePosTime)
end

local function GetPositionNode()
  if #PositionPool > 0 then
    return table.remove(PositionPool, #PositionPool)
  else
    Log.Debug("[MovementComponent]Create New Position...", #PositionPool)
    return _G.ProtoMessage:newPosition()
  end
end

local function ReturnMoveSegmentNodes(List)
  for i = #List, 1, -1 do
    local Node = table.remove(List, i)
    table.insert(PositionPool, Node.pos)
    Node.pos = false
    table.insert(MoveSegmentPool, Node)
  end
end

local function GetMoveSegment()
  if #MoveSegmentPool > 0 then
    return table.remove(MoveSegmentPool, #MoveSegmentPool)
  else
    Log.Debug("[MovementComponent]Create New MoveSegment...", #MoveSegmentPool)
    return {pos = false, time_stamp = 0}
  end
end

function MovementComponent:Ctor()
  self.ZeroVector = UE4.FVector(0)
  self._lastInputVector = self.ZeroVector
  self._lastConsumedVector = self.ZeroVector
  self._moveReq = ProtoMessage:newZoneSceneMoveReq()
  self._matePoint = ProtoMessage:newPoint()
  self._moveReq.stop_move = true
  self._moveReq.platform_actor_id = 0
  self._isBanned = false
  self._isSyncMove = true
  self.lazySyncTime = _G.DataConfigManager:GetGlobalConfigNumByKeyType("lazy_move_sync_time", _G.DataConfigManager.ConfigTableId.GLOBAL_CONFIG, 100)
  self._cachePos = CurrentCachePos
  self._cachePosTime = CurrentCachePosTime
end

function MovementComponent:Attach(owner)
  Base.Attach(self, owner)
  self._enableDelay = 5
  FunctionBanManager:AddFunctionStateListener(Enum.PlayerFunctionBanType.PFBT_MOVE, self, self.OnBanMove)
  self.owner:AddEventListener(self, PlayerModuleEvent.PLAYER_MOVEMENT_MODE_CHANGE, self.OnMovementModeChanged)
  self.owner:AddEventListener(self, PlayerModuleEvent.ON_RIDEPET_CHANGE_MOVETYPE, self.OnRidePetChangeMoveType)
end

function MovementComponent:DeAttach()
  FunctionBanManager:RemoveFunctionStateListener(Enum.PlayerFunctionBanType.PFBT_MOVE, self, self.OnBanMove)
  self.owner:RemoveEventListener(self, PlayerModuleEvent.PLAYER_MOVEMENT_MODE_CHANGE, self.OnMovementModeChanged)
  self.owner:RemoveEventListener(self, PlayerModuleEvent.ON_RIDEPET_CHANGE_MOVETYPE, self.OnRidePetChangeMoveType)
end

function MovementComponent:OnMovementModeChanged(PreMoveMode, CurMoveMode, PreCustomMode, CurCustomMode)
  if CurMoveMode == UE.EMovementMode.MOVE_Custom and CurCustomMode == UE.ERocoCustomMovementMode.MOVE_Climbing or PreMoveMode == UE.EMovementMode.MOVE_Custom and PreCustomMode == UE.ERocoCustomMovementMode.MOVE_Climbing then
    self.owner.viewObj:ClearMoveInput()
    self:ClearMoveInput()
  end
  if _G.GlobalConfig.bDebugMoveLog then
    Log.Debug("[DebugMove1P][MovementComponent] OnMovementModeChanged, MoveMode:", PreMoveMode, "->", CurMoveMode, "CustomMode:", PreCustomMode, "->", CurCustomMode)
  end
  if 0 == CurMoveMode and 0 == CurCustomMode then
    return
  end
  if 0 == CurMoveMode then
    local _, isRiding = self:GetActiveMovement()
    if self.owner and self.owner.statusComponent and isRiding then
      return
    end
    self:SendMoveReq(true, true)
  else
    self:SendMoveReq(true, false)
  end
end

function MovementComponent:OnRidePetChangeMoveType()
  if _G.GlobalConfig.bDebugMoveLog then
    Log.Debug("[DebugMove1P][MovementComponent] OnRidePetChangeMoveType")
  end
  local _, isRiding = self:GetActiveMovement()
  if self.owner and self.owner.statusComponent and not isRiding then
    return
  end
  self:SendMoveReq(true, false)
end

function MovementComponent:OnBanMove(newState, functionType, id)
  if newState then
    local conf = _G.DataConfigManager:GetFunctionBanConf(id, true)
    local banDesc = conf and conf.ban_desc or "unknown"
    Log.Debug("[OnBanMove] ", id, banDesc)
  end
  self._isBanned = newState
end

function MovementComponent:SetSyncMove(value)
  Log.Debug("[DebugMove1P][MovementComponent] SetSyncMove", value)
  self._isSyncMove = value
end

function MovementComponent:SimpleMove(inputVector)
  if not self.owner or not self.owner.viewObj then
    Log.Debug("MovementComponent not owner or not owner.viewObj")
    return
  end
  local pawn = self.owner.viewObj
  local moveLength = inputVector:Size()
  local moveVector = inputVector
  pawn:AddMovementInput(moveVector, moveLength)
end

function MovementComponent:ApplyMoveInput(dir, axis)
  if self._isBanned then
    return
  end
  self:ApplyMoveInputVector(dir * axis)
end

function MovementComponent:ApplyMoveInputVector(inputVector)
  if UE4Helper.IsNonZeroVector(inputVector) then
    self._lastInputVector = self._lastInputVector + inputVector
    local pawn = self.owner.viewObj
    if pawn and not pawn.HasMovementInput then
      pawn.HasMovementInput = true
    end
  else
    self._lastInputVector = inputVector
  end
end

function MovementComponent:ConsumeInput()
  local pawn = self.owner.viewObj
  local inputVector = self._lastInputVector
  self._lastConsumedVector = inputVector
  self._lastInputVector = self.ZeroVector
  if pawn and pawn.HasMovementInput then
    pawn.HasMovementInput = false
  end
  if 0 == self._lastConsumedVector:Size() then
    self.owner:SendEvent(PlayerModuleEvent.ON_PLAYER_NO_MOVE_INPUT)
  end
  return self._lastConsumedVector
end

function MovementComponent:ClearMoveInput()
  self._lastConsumedVector = self.ZeroVector
  self._lastInputVector = self.ZeroVector
end

local lastInputVectorCache = UE4.FVector()

function MovementComponent:HasMoveInput()
  local lastInputVector = self._lastConsumedVector
  if UE4Helper.IsNonZeroVector(lastInputVector) then
    return true
  elseif self.owner and self.owner.viewObj then
    lastInputVector = lastInputVectorCache
    UE4.UNRCStatics.GetLastMovementInputVectorFromPawnInplace(self.owner.viewObj, lastInputVector)
    if UE4Helper.IsNonZeroVector(lastInputVector) then
      return true
    end
  end
  return false
end

function MovementComponent:GetLastInput()
  return self._lastInputVector
end

function MovementComponent:Update(deltaTime)
  if not self.owner.ueController or not self.owner.ueController.Pawn then
    return
  end
  local inputVector = self:ConsumeInput()
  if self:HasMoveInput() and UE4Helper.IsNonZeroVector(inputVector) then
    self:SimpleMove(inputVector)
  end
  if self._enableDelay > 0 then
    self._enableDelay = self._enableDelay - deltaTime
    self:ClearMovingTagOnce()
    return
  end
  local bAlreadySent = false
  local bIsMoving = self:IsMoving()
  local ActiveMovement, _ = self:GetActiveMovement()
  if bIsMoving or ActiveMovement and ActiveMovement.bIsMantle then
    if self.isMovingTagOnce and #self.isMovingTagOnce > 0 then
      bAlreadySent = self:SendMoveReq(true, false)
    else
      bAlreadySent = self:SendMoveReq(false, false)
    end
  elseif not bIsMoving then
    if self._moveReq.stop_move == false or self._moveReq.stop_move == nil then
      bAlreadySent = self:SendMoveReq(false, true)
    elseif self._cachePos and #self._cachePos > 0 then
      bAlreadySent = self:SendMoveReq(false, true)
    end
  end
  if not bAlreadySent and (self:CheckVelBigChange() or self:CheckDistBigChange()) then
    bAlreadySent = self:SendMoveReq(true, false)
  end
  self:ClearMovingTagOnce()
end

function MovementComponent:DoSendMoveReq(bStopMoveReq, bIgnorePlatformActor, platform_actor_id)
  if not self._isSyncMove then
    Log.Error("[DebugMove1P] MovementComponent:DoSendMoveReq failed, _isSyncMove is false!")
    return false
  end
  local nativeMovementComponent, bRiding = self:GetActiveMovement()
  if not nativeMovementComponent then
    Log.Error("[DebugMove1P] MovementComponent:DoSendMoveReq failed, nativeMovementComponent is nil!")
    return
  end
  local updatedComponent = nativeMovementComponent.UpdatedComponent
  local location = updatedComponent:Abs_K2_GetComponentLocation()
  local cachePosList = self._cachePos
  local cachePosTimeList = self._cachePosTime
  SwapCachePosList()
  self._cachePos = CurrentCachePos
  self._cachePosTime = CurrentCachePosTime
  local moveMode = nativeMovementComponent.MovementMode
  self._moveReq.move_mode = moveMode
  self._moveReq.custom_mode = nativeMovementComponent.CustomMovementMode
  local SceneModule = _G.NRCModuleManager:GetModule("SceneModule")
  if SceneModule then
    self._moveReq.scene_cfg_id = SceneModule:GetCurrentMapId()
  end
  self._moveReq.ride_move = bRiding
  SceneUtils.PlayerPos2ServerPos(location, nil, self._moveReq.to_pos)
  local rotation = updatedComponent:K2_GetComponentRotation()
  SceneUtils.ClientRotator2ServerPos(rotation, nil, self._moveReq.to_rot)
  if moveMode ~= UE4.EMovementMode.MOVE_Custom or self._moveReq.custom_mode ~= UE4.ERocoCustomMovementMode.MOVE_Climbing then
    if 0 ~= self._moveReq.to_rot.x then
      Log.Debug("[DebugMove1P] DoSendMoveReq, to_rot Roll is not zero!")
      self._moveReq.to_rot.x = 0
    end
    if 0 ~= self._moveReq.to_rot.y then
      Log.Debug("[DebugMove1P] DoSendMoveReq, to_rot Pitch is not zero!")
      self._moveReq.to_rot.y = 0
    end
  end
  local CtrlRotation = self.owner.ueController:GetControlRotation()
  SceneUtils.ClientRotator2ServerPos(CtrlRotation, nil, self._moveReq.ctrl_rot)
  if 3 == moveMode and nativeMovementComponent.Velocity:IsNearlyZero(0.01) then
    Log.Debug("[DebugMove1P] Falling with zero velocity, use old velocity!", nativeMovementComponent.Velocity, self._moveReq.speed.x, self._moveReq.speed.y, self._moveReq.speed.z)
  else
    SceneUtils.ClientPos2ServerPos(nativeMovementComponent.Velocity, nil, self._moveReq.speed)
  end
  SceneUtils.ClientPos2ServerPos(nativeMovementComponent:GetCurrentAcceleration(), nil, self._moveReq.acceleration)
  self._moveReq.time_stamp = _G.ZoneServer:GetServerTime()
  if bStopMoveReq then
    self._moveReq.stop_move = true
  elseif SceneUtils.IsNearlyZero(self._moveReq.speed) then
    self._moveReq.stop_move = true
  else
    self._moveReq.stop_move = false
  end
  ReturnMoveSegmentNodes(self._moveReq.move_seg_list)
  if cachePosList and cachePosTimeList and #cachePosList > 0 and #cachePosTimeList > 0 then
    for i = 1, #cachePosList do
      local seg = GetMoveSegment()
      seg.pos = cachePosList[i]
      seg.time_stamp = cachePosTimeList[i]
      table.insert(self._moveReq.move_seg_list, seg)
    end
  end
  if bIgnorePlatformActor then
    self._moveReq.platform_actor_id = 0
  elseif platform_actor_id and type(platform_actor_id) == "number" then
    self._moveReq.platform_actor_id = platform_actor_id
  else
    self:FillPlatformActorId(self._moveReq, nativeMovementComponent)
  end
  local matePos, mateRot, mateMoveMode = self:GetMatePosRot()
  local hasMate = matePos and mateRot
  if hasMate then
    if not self._moveReq.mate_point then
      self._moveReq.mate_point = self._matePoint
    end
    self._moveReq.mate_point.pos = SceneUtils.PlayerPos2ServerPos(matePos, nil, self._moveReq.mate_point.pos)
    self._moveReq.mate_point.dir = SceneUtils.ClientRotator2ServerPos(mateRot, nil, self._moveReq.mate_point.dir)
    self._moveReq.mate_move_mode = mateMoveMode
  else
    self._moveReq.mate_point = nil
  end
  if _G.GlobalConfig.bDebugMoveLog then
    local ownerUin = self.owner:GetLogicId()
    Log.DebugFormat("[DebugMove1P][MovementComponent] DoSendMoveReq:(%d),RideMove(%d),Location(%s),Rotation(%s),MovementMode(%d),CustomMode(%d),LinearVelocity(%s),TimeStamp(%d),StopMove(%d),platform_actor_id(%d),GFrameNumber(%d)", ownerUin, self._moveReq.ride_move and 1 or 0, location, rotation, self._moveReq.move_mode, self._moveReq.custom_mode, string.format("%.1f,%.1f,%.1f", self._moveReq.speed.x or 0, self._moveReq.speed.y or 0, self._moveReq.speed.z or 0), self._moveReq.time_stamp, self._moveReq.stop_move and 1 or 0, self._moveReq.platform_actor_id, UE4.UNRCStatics.GetCurGFrameNumber())
    if hasMate then
      Log.DebugFormat("[DebugMove1P][MovementComponent] DoSendMoveReq#2:(%d),MatePos(%s),MateRot(%s),MateMoveMode(%d)", ownerUin, matePos, mateRot, mateMoveMode and mateMoveMode or 0)
    end
  end
  ZoneServer:Send(ProtoCMD.ZoneSvrCmd.ZONE_SCENE_MOVE_REQ, self._moveReq)
  self.owner.module:DispatchEvent(PlayerModuleEvent.ON_SEND_MOVE_DATA, self._moveReq)
end

function MovementComponent:GetReqMoveInterval()
  if self.owner:IsInTogetherMove() then
    return UE4.UNRCStatics.GetConsoleVarInt32("Roco.Move.ReqInterval2PRider")
  end
  return UE4.UNRCStatics.GetConsoleVarInt32("Roco.Move.ReqInterval")
end

function MovementComponent:SendMoveReq(bForceSend, bStopMoveReq)
  if not GlobalConfig.SyncMovement then
    return false
  end
  if not self._isSyncMove then
    return false
  end
  if not _G.ZoneServer:IsEnteredCell() then
    return false
  end
  if self.owner:IsTogetherMove2P() then
    return false
  end
  local reqMoveInterval = self:GetReqMoveInterval()
  local curServerTime = _G.ZoneServer:GetServerTime()
  local lastSyncMoveTime = self._moveReq.time_stamp or 0
  local elapsedTime = curServerTime - lastSyncMoveTime
  if not bForceSend and not bStopMoveReq and reqMoveInterval > elapsedTime then
    return false
  end
  local nativeMovementComponent = self:GetActiveMovement()
  if not nativeMovementComponent then
    return false
  end
  local updatedComponent = nativeMovementComponent.UpdatedComponent
  local location = updatedComponent:Abs_K2_GetComponentLocation()
  local OwnerPlayer = self.owner
  if OwnerPlayer:CanLazySyncMove() and not bForceSend and not bStopMoveReq then
    local lazyElapsedTime = elapsedTime
    if #self._cachePos > 0 and #self._cachePosTime > 0 then
      local lastCacheServerTime = self._cachePosTime[#self._cachePosTime]
      lazyElapsedTime = curServerTime - lastCacheServerTime
    end
    if lazyElapsedTime > 3 * reqMoveInterval then
      table.insert(self._cachePos, SceneUtils.PlayerPos2ServerPos(location, nil, GetPositionNode()))
      table.insert(self._cachePosTime, curServerTime)
    end
    if elapsedTime < self.lazySyncTime then
      return false
    end
  end
  self:DoSendMoveReq(bStopMoveReq)
  return true
end

function MovementComponent:SendMoveReqImmediately(bIgnorePlatformActor, platform_actor_id)
  Log.Debug("[MovementComponent] SendMoveReqImmediately!", bIgnorePlatformActor, platform_actor_id)
  self:DoSendMoveReq(false, bIgnorePlatformActor, platform_actor_id)
end

function MovementComponent:Record()
end

function MovementComponent:OnPause(pause)
  if self.owner then
    self.owner:SetCharacterMovementTickEnable(self, not pause, "Pause")
  end
end

function MovementComponent:OnDisable()
  self._lastInputVector = self.ZeroVector
  self._lastConsumedVector = self.ZeroVector
end

function MovementComponent:IsDiffMode()
  if not (self.owner and self.owner.ueController) or not self.owner.ueController.Pawn then
    Log.Debug("MovementComponent:owner or ctrl or pawn is destoryed")
    return false
  end
  local nativeMovementComponent = self:GetActiveMovement()
  return self._moveReq.move_mode ~= nativeMovementComponent.MovementMode or self._moveReq.custom_mode ~= nativeMovementComponent.CustomMovementMode
end

function MovementComponent:GetActiveMovement()
  if not (self.owner and self.owner.ueController and UE4.UObject.IsValid(self.owner.ueController) and self.owner.ueController.Pawn) or not UE4.UObject.IsValid(self.owner.ueController.Pawn) then
    Log.Debug("MovementComponent:owner or ctrl or pawn is destoryed")
    return nil, false
  end
  local nativeMovementComponent = self.owner.ueController.Pawn.CharacterMovement
  local bRiding = false
  if self.owner.statusComponent:HasStatus(Enum.WorldPlayerStatusType.WPST_RIDEALL) then
    local ridePawn = self.owner.viewObj.BP_RideComponent.RidePet
    if ridePawn then
      nativeMovementComponent = ridePawn.CharacterMovement
      bRiding = true
    end
  end
  return nativeMovementComponent, bRiding
end

function MovementComponent:FillPlatformActorId(moveReq, nativeMoveComponent)
  if moveReq then
    local oldActorId = moveReq.platform_actor_id
    local newActorId = 0
    moveReq.platform_actor_id = 0
    if nativeMoveComponent then
      local stepUpActor = nativeMoveComponent:GetCurStepUpActor()
      if UE4.UObject.IsValid(stepUpActor) and stepUpActor.IsA and stepUpActor:IsA(UE.ANPCBaseActor) and stepUpActor.resourceLoaded then
        local npcActor = stepUpActor.sceneCharacter
        if npcActor and npcActor.serverData and npcActor.serverData.base then
          moveReq.platform_actor_id = npcActor.serverData.base.actor_id
          newActorId = moveReq.platform_actor_id
        end
      end
    end
    local SceneModule = NRCModuleManager:GetModule("SceneModule")
    if _G.NRCModuleManager:DoCmd(_G.NPCModuleCmd.CheckInitialNPCsReady) and SceneModule and not SceneModule.bWaitingForAckEnd then
      local OwnerPlayer = self.owner
      if OwnerPlayer then
        if oldActorId ~= newActorId then
          Log.Debug("MovementComponent:FillPlatformActorId change platform_actor_id", moveReq.platform_actor_id)
        end
        OwnerPlayer.serverData.base.platform_actor_id = moveReq.platform_actor_id
      end
    end
  end
end

local TempVelHolder = UE4.FVector(0, 0, 0)

function MovementComponent:CheckDistBigChange()
  if not self:IsMoving() then
    return false
  end
  local nativeMovementComponent = self:GetActiveMovement()
  if not nativeMovementComponent then
    return false
  end
  local PrePos = SceneUtils.ServerPos2ClientPosInPlace(self._moveReq.to_pos, nil, TempVelHolder)
  local updatedComponent = nativeMovementComponent.UpdatedComponent
  local CurPos = updatedComponent:Abs_K2_GetComponentLocation()
  local DistSqured = UE4.FVector.DistSquared(PrePos, CurPos)
  if DistSqured < MAX_DIST_CHANGE * MAX_DIST_CHANGE then
    return false
  end
  return true
end

function MovementComponent:CheckVelBigChange()
  local nativeMovementComponent = self:GetActiveMovement()
  if not nativeMovementComponent then
    return false
  end
  local OwnerPlayer = self.owner
  if OwnerPlayer and OwnerPlayer:CanLazySyncMove() then
    return false
  end
  local PreVel = SceneUtils.ServerPos2ClientPosInPlace(self._moveReq.speed, nil, TempVelHolder)
  local CurVel = nativeMovementComponent.Velocity
  if PreVel:IsNearlyZero(1.0E-4) and not CurVel:IsNearlyZero(1.0E-4) then
    if _G.GlobalConfig.bDebugMoveLog then
      Log.Debug("[DebugMove1P][MovementComponent] CheckVelBigChange, 0 ->", CurVel)
    end
    return true
  end
  if CurVel:IsNearlyZero(1.0E-4) then
    return false
  end
  local DotValue = CurVel:Dot(PreVel) / (PreVel:Size() * CurVel:Size())
  if DotValue < MAX_VEL_ANG_CHANGE_DOT then
    if _G.GlobalConfig.bDebugMoveLog then
      Log.Debug("[DebugMove1P][MovementComponent] detect a big velocity change,", DotValue, MAX_VEL_ANG_CHANGE_DOT)
    end
    return true
  end
  return false
end

function MovementComponent:GetMatePosRot()
  if self.owner and UE.UObject.IsValid(self.owner.viewObj) then
    local linkChild = self.owner.viewObj.LinkComponent.Child
    if UE.UObject.IsValid(linkChild) and UE.UObject.IsValid(linkChild.RocoPlayer) then
      local location = linkChild.RocoPlayer:Abs_K2_GetActorLocation()
      local rotation = linkChild.RocoPlayer:K2_GetActorRotation()
      local moveMode = linkChild.RocoPlayer.CharacterMovement.MovementMode
      return location, rotation, moveMode
    end
  end
  return nil, nil
end

return MovementComponent

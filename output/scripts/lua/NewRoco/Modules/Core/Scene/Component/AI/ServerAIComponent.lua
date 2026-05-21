local Base = require("NewRoco.Modules.Core.Scene.Component.ActorComponent")
local AIDefines = require("NewRoco.AI.AIDefines")
local Queue = require("Utils.Queue")
local SceneAnimEnum = require("NewRoco.Modules.Core.Scene.Common.SceneAnimEnum")
local NPCModuleEnum = require("NewRoco.Modules.Core.NPC.NPCModuleEnum")
local SceneUtils = require("NewRoco.Modules.Core.Scene.Common.SceneUtils")
local _localNRCModuleManager = NRCModuleManager
local LuaMathUtils = require("NewRoco.Utils.LuaMathUtils")
local ServerAIDebugger = require("NewRoco.Modules.Core.Scene.Component.AI.ServerAIDebugger")
local ServerAICommandEnum = require("NewRoco.Modules.Core.Scene.Component.AI.ServerAICommandEnum")
local HangingComponent = require("NewRoco.Modules.Core.Scene.Component.Movement.HangingComponent")
local AttackComponent = require("NewRoco.Modules.Core.Scene.Component.Attack.AttackComponent")
local BezierFlyComponent = require("NewRoco.Modules.Core.Scene.Component.Movement.BezierFlyComponent")
local HiddenComponent = require("NewRoco.Modules.Core.Scene.Component.Hidden.HiddenComponent")
local SocketSnapComponent = require("NewRoco.Modules.Core.Scene.Component.Movement.SocketSnapComponent")
local RocoSkillProxy = require("NewRoco.Utils.RocoSkillProxy")
local RealtimeDialogModuleCmd = require("NewRoco.Modules.System.RealtimeDialog.RealtimeDialogModuleCmd")
local a = require("Common.Coroutine.async")
local au = require("Common.Coroutine.async_util")
local AIStateLookAtCamera = require("NewRoco.AI.State.AIStateLookAtCamera")
local FIFOimme = true
local LegacyMove = false
local ServerAIComponent = Base:Extend("ServerAIComponent")

function ServerAIComponent:Ctor()
  self.owner = nil
  self.event_queue = nil
  self.command_func = {}
  self.seq_id = 0
  self.isServerMoving = false
  self.cacheServerMoveReq = nil
  self.currentSvrMoveIdx = 1
  self.currentSvrMoveTargetPoint = nil
  self.timeCompensation = 0
  self.isServerAttaching = false
  self.activeAttachParam = nil
  self.lastTickTime = 0
  self.reportPositionAfterNextSkill = false
  self.hideState = false
  self.persistAnimTimerHandle = nil
  self.currentPersistAnimName = nil
  self.recording_move = false
  self.skillProxyMap = {}
  self.skillInterruptFlagMap = {}
  self._forceLockRegistered = false
end

ServerAIComponent.command_func = {}
ServerAIComponent.bBindFunction = false
ServerAIComponent.HoldOnEndAnimationNames = {
  "SitDownStart",
  "SitDownLoop",
  "SleepLoop"
}

function ServerAIComponent:BindFunction()
  if ServerAIComponent.bBindFunction then
    return
  end
  ServerAIComponent.command_func = {
    [ServerAICommandEnum.ServerAICommandEvent.PlayAnimation] = ServerAIComponent.PlayAnimation,
    [ServerAICommandEnum.ServerAICommandEvent.StopAnimation] = ServerAIComponent.StopAnimation,
    [ServerAICommandEnum.ServerAICommandEvent.AnimPauseOrResume] = ServerAIComponent.AnimPauseOrResume,
    [ServerAICommandEnum.ServerAICommandEvent.ServerMove] = ServerAIComponent.ServerMove,
    [ServerAICommandEnum.ServerAICommandEvent.InterruptServerMove] = ServerAIComponent.InterruptServerMove,
    [ServerAICommandEnum.ServerAICommandEvent.TurnTo] = ServerAIComponent.TurnTo,
    [ServerAICommandEnum.ServerAICommandEvent.CancelTurnTo] = ServerAIComponent.CancelTurnTo,
    [ServerAICommandEnum.ServerAICommandEvent.WorldAttack] = ServerAIComponent.WorldAttack,
    [ServerAICommandEnum.ServerAICommandEvent.StopWorldAttack] = ServerAIComponent.StopWorldAttack,
    [ServerAICommandEnum.ServerAICommandEvent.PlayPerceptionEffect] = ServerAIComponent.PlayPerceptionEffect,
    [ServerAICommandEnum.ServerAICommandEvent.PlayPerceptionHud] = ServerAIComponent.PlayPerceptionHud,
    [ServerAICommandEnum.ServerAICommandEvent.PerceivePlayer] = ServerAIComponent.PerceivePlayer,
    [ServerAICommandEnum.ServerAICommandEvent.PlayChatBubble] = ServerAIComponent.PlayChatBubble,
    [ServerAICommandEnum.ServerAICommandEvent.ServerAttach] = ServerAIComponent.ServerAttach,
    [ServerAICommandEnum.ServerAICommandEvent.CancelServerAttach] = ServerAIComponent.CancelServerAttach,
    [ServerAICommandEnum.ServerAICommandEvent.PlaySkill] = ServerAIComponent.PlaySkill,
    [ServerAICommandEnum.ServerAICommandEvent.StopSkill] = ServerAIComponent.StopSkill,
    [ServerAICommandEnum.ServerAICommandEvent.CollisionCancelRecover] = ServerAIComponent.CollisionCancelRecover,
    [ServerAICommandEnum.ServerAICommandEvent.WorldHidden] = ServerAIComponent.WorldHidden,
    [ServerAICommandEnum.ServerAICommandEvent.WorldUnhidden] = ServerAIComponent.WorldUnhidden,
    [ServerAICommandEnum.ServerAICommandEvent.LookAt] = ServerAIComponent.LookAt,
    [ServerAICommandEnum.ServerAICommandEvent.ServerFly] = ServerAIComponent.ServerFly,
    [ServerAICommandEnum.ServerAICommandEvent.PlayZoomAnimation] = ServerAIComponent.PlayZoomAnimation,
    [ServerAICommandEnum.ServerAICommandEvent.PlayVoice] = ServerAIComponent.PlayVoice,
    [ServerAICommandEnum.ServerAICommandEvent.Launch] = ServerAIComponent.Launch,
    [ServerAICommandEnum.ServerAICommandEvent.CancelLaunch] = ServerAIComponent.CancelLaunch,
    [ServerAICommandEnum.ServerAICommandEvent.PlayRealtimeDialog] = ServerAIComponent.PlayRealtimeDialog,
    [ServerAICommandEnum.ServerAICommandEvent.StopRealtimeDialog] = ServerAIComponent.StopRealtimeDialog,
    [ServerAICommandEnum.ServerAICommandEvent.StickTo] = ServerAIComponent.StickTo,
    [ServerAICommandEnum.ServerAICommandEvent.FinishStickTo] = ServerAIComponent.FinishStickTo,
    [ServerAICommandEnum.ServerAICommandEvent.SetNpcPos] = ServerAIComponent.SetNpcPos,
    [ServerAICommandEnum.ServerAICommandEvent.TryInteractNpc] = ServerAIComponent.TryInteractNpc,
    [ServerAICommandEnum.ServerAICommandEvent.VelocityOrientRotation] = ServerAIComponent.VelocityOrientRotation,
    [ServerAICommandEnum.ServerAICommandEvent.WorldLaunchPlayer] = ServerAIComponent.WorldLaunchPlayer
  }
  ServerAIComponent.bBindFunction = true
end

function ServerAIComponent:Attach(owner)
  Base.Attach(self, owner)
  self.owner = owner
  self.AIComp = owner.AIComponent
  self.event_queue = Queue()
  self:BindFunction()
  if RocoEnv.IS_EDITOR then
    self.debugger = ServerAIDebugger()
    self.debugger:Bind(self)
  end
  self.lastTickTime = _G.ZoneServer:GetServerTime()
  self.locked = false
  self.init_move_info = nil
  local aiInfo = self.owner.serverData.ai_info
  if aiInfo then
    self.seq_id = aiInfo.ai_seq_id or 0
    self.hideState = aiInfo.is_hidden or false
    self.init_move_info = aiInfo.ai_move_info
  end
  self.recording_move = self.AIComp and self.AIComp.isServerAI and not self.AIComp:IsControllerValid()
  self.critical = self.owner.config.genre == Enum.ClientNpcType.CNT_PETBOSS
end

function ServerAIComponent:DeAttach()
  Base.DeAttach(self)
  if self.persistAnimTimerHandle then
    _G.DelayManager:CancelDelayById(self.persistAnimTimerHandle)
    self.persistAnimTimerHandle = nil
    self.currentPersistAnimName = nil
  end
  if self.debugger then
    self.debugger:Unbind()
    self.debugger = nil
  end
  if self.event_queue then
    self.event_queue:Clear()
    self.event_queue = nil
  end
  self:_CleanAllSkillProxies(true)
  self.AIComp = nil
  self.owner = nil
end

function ServerAIComponent:UpdateData(ServerData, isReconnect)
  if isReconnect and ServerData.npc_base and ServerData.npc_base.is_server_ai then
    local HidComp = self.owner.HiddenComponent
    if HidComp then
      self.hideState = HidComp:CanHide() and self.owner:IsLogicStatus(HidComp:GetLogicStatus())
    end
    if self.AIComp:IsControllerValid() then
      local view = self.owner.viewObj
      if view and UE.UObject.IsValid(view) then
        local current = view:Abs_K2_GetActorLocation()
        local target = SceneUtils.ServerPos2ClientPos(ServerData.base.pt.pos)
        local distance = current:Dist2D(target)
        if distance > 120 then
          local rotation = SceneUtils.ServerPos2ClientRotator(ServerData.base.pt.dir)
          local halfHeight = self.owner:GetHalfHeight()
          local pinnedTarget = SceneUtils.GetPosInLand(target, halfHeight, 2 * halfHeight)
          if pinnedTarget and pinnedTarget.Z > target.Z then
            target.Z = pinnedTarget.Z
          end
          view:Abs_K2_SetActorLocationAndRotation_WithoutHit(target, rotation, false, true)
        end
      end
    end
  end
end

function ServerAIComponent:GetCurrentTime()
  return _G.ZoneServer:GetServerTime()
end

function ServerAIComponent:OnControllerCreated()
  if self.AIComp and self.AIComp.isServerAI then
    self:EvalMovePosAndSet()
  end
end

function ServerAIComponent:OnControllerDestroy()
  self.recording_move = self.AIComp and self.AIComp.isServerAI
  self:_CleanAllSkillProxies(true)
end

function ServerAIComponent:OnDistanceOptimize(distance, viewDotValue, bulkyVisible, distanceRatio)
  if self.debugger then
    self.debugger:EnableTick(GlobalConfig.DebugLuaBTree and distanceRatio < 0.5)
  end
end

function ServerAIComponent:UpdateByDistance(deltaTime)
  local currentTime = self:GetCurrentTime()
  self.realDeltaTime = (currentTime - self.lastTickTime) / 1000.0
  if not self.locked and self.isServerMoving then
    self:TickServerMove(self.realDeltaTime)
  end
  if self.isServerAttaching then
    self:UpdateTransform(self.realDeltaTime)
  end
  self.timeCompensation = LuaMathUtils.LerpWithMin(self.timeCompensation, 0, 25, math.min(deltaTime * 1.5, 1))
  self:DequeueEvent(currentTime)
  self.lastTickTime = currentTime
end

function ServerAIComponent:DequeueEvent(currentTime)
  local event_num = math.min(self.event_queue:Size(), 5)
  while event_num > 0 do
    event_num = event_num - 1
    local command = self.event_queue:First()
    local time_over = currentTime - command.time_stamp
    if time_over > 0 then
      self.seq_id = command.seq_id
      local commandFunc = ServerAIComponent.command_func[command.command_enum]
      if commandFunc then
        commandFunc(self, command.server_data, time_over)
      end
      self.event_queue:RemoveFirst()
    else
      break
    end
  end
  self:OnApplyTransform()
end

function ServerAIComponent:EnqueueEvent(eventType, action, baseData, syncData)
  if not self.owner then
    return
  end
  local newEvent = ServerAICommandEnum.newServerAICommand()
  newEvent.command_enum = eventType
  newEvent.time_stamp = baseData.space_time_ms
  newEvent.seq_id = syncData and syncData.ai_seq_id or 0
  newEvent.server_data = action
  if self.owner.viewObj then
    self.event_queue:Enqueue(newEvent)
  end
  if FIFOimme then
    self:DequeueEvent(newEvent.time_stamp + 1)
  else
    local isMoveEvent = newEvent.command_enum == ServerAICommandEnum.ServerAICommandEvent.ServerMove or newEvent.command_enum == ServerAICommandEnum.ServerAICommandEvent.InterruptServerMove
    local isLagged = self.event_queue:Size() > 5
    if isMoveEvent or isLagged then
      if isLagged then
        Log.Debug("[ServerAIComponent] Dequeue Event for lagging reason", self.owner:GetServerId(), self.owner.config.id)
      end
      self:DequeueEvent(newEvent.time_stamp + 1)
    end
  end
end

function ServerAIComponent:GetEventQueue()
  return self.event_queue
end

function ServerAIComponent:ForceLock(lock)
  if LegacyMove then
    if lock then
      self.isServerMoving = false
    else
      self:DoNextSvrMove(true)
    end
  else
    self.locked = lock
    if lock then
      self:PauseMove()
    else
      self:ResumeMove()
      self:UpdateHideState()
    end
  end
end

function ServerAIComponent:PlayAnimation(action, time_over)
  if self.locked then
    return false
  end
  local isLoop = action.loop_count > 9999 or action.loop_count < 0
  local isPause = action.pause_on_end
  local persistAnim = isLoop or isPause
  if self.owner.serverData and persistAnim and not self.owner.serverData.ai_info then
    self.owner.serverData.ai_info = _G.ProtoMessage:newActorInfo_AI()
    local info = self.owner.serverData.ai_info
    info.anim_rate = action.play_rate
    info.anim_is_loop = isLoop
    info.anim_id = action.anim_id
  end
  if not persistAnim and time_over > 1000 then
    return false
  end
  local animConf = _G.DataConfigManager:GetAnimIdConf(action.anim_id, true)
  local animName = animConf and animConf.anim_name or nil
  if nil == animName then
    Log.PrintScreenMsg("[ServerAIComponent:PlayAnimation] Can't find anim with id %u for npc %d %s", action.anim_id, self.owner.config.id, self.owner.config.name)
  else
    local AnimComp = self.owner:GetAnimComponent()
    if not AnimComp then
      return true
    end
    if action.is_rootmotion and action.actor_dir and action.actor_dir.x then
      local Rot = SceneUtils.ServerPos2ClientRotator(action.actor_dir)
      self.owner:SetActorRotation(Rot)
    end
    local isAnimPlaying = AnimComp:IsAnimPlaying(animName)
    if nil == self.owner.viewObj then
      Log.Error("ServerAIComponent:PlayAnimation cant get viewobj")
      return false
    end
    if isAnimPlaying then
      self.owner:OverrideCurrentAnimRate(action.play_rate)
    else
      if self.persistAnimTimerHandle then
        _G.DelayManager:CancelDelayById(self.persistAnimTimerHandle)
        self.persistAnimTimerHandle = nil
      end
      local bHoldOnEnd = not isLoop and self:IsHoldOnEndAnimation(animName)
      if bHoldOnEnd then
        local AnimComp = self.owner:GetAnimComponent()
        if AnimComp then
          local animLength = AnimComp:GetAnimLengthByName(animName)
          if animLength and animLength > 0 then
            self.currentPersistAnimName = animName
            local actualDuration = animLength / (action.play_rate > 0 and action.play_rate or 1) + 1
            self.persistAnimTimerHandle = _G.DelayManager:DelaySeconds(actualDuration, self.OnPersistAnimationTimer, self)
          end
        end
      end
      if action.movement_mode and 5 == action.movement_mode then
        local moveComp = self.owner.viewObj:GetMovementComponent()
        if moveComp then
          moveComp:SetMovementMode(UE.EMovementMode.MOVE_Flying)
        end
      end
      self.owner:PlayAnim(animName, action.play_rate, action.start_pos, action.blend_in_time, (action.pause_on_end or bHoldOnEnd) and -1 or action.blend_out_time, action.loop_count)
      if not action.mute then
        UE.URocoAIHelper.PlayAudioOnPawn(self.owner.viewObj, self.owner:GetPetbaseId() or 0, animName, action.voice_speed, action.high_priority)
      end
    end
  end
  return true
end

function ServerAIComponent:StopAnimation(action)
  if self.locked then
    return false
  end
  local animConf = _G.DataConfigManager:GetAnimIdConf(action.anim_id, true)
  local animName = animConf and animConf.anim_name or nil
  if nil == animName then
    Log.WarningFormat("[ServerAIComponent:StopAnimation] Can't find anim with id %u", action.anim_id)
  else
    self.owner:StopAnim(animName)
  end
  return true
end

function ServerAIComponent:AnimPauseOrResume(action, time_over)
  if self.locked then
    return false
  end
  if time_over > 1000 then
    return false
  end
  if action.is_anim_pause then
    self.owner:PauseAnim()
  else
    self.owner:ResumeAnim()
  end
  return true
end

local LuaActionPlayZoomAnimation = require("NewRoco.AI.BehaviorTree.Actions.LuaActionPlayZoomAnimation")

function ServerAIComponent:PlayZoomAnimation(action, time_over)
  if self.locked then
    return false
  end
  local Target = SceneUtils.ServerPos2ClientPos(action.target_pos)
  if time_over > 1000 then
    self:SetCacheLocation(Target)
    return
  end
  local View = self.owner.viewObj
  if not View then
    return
  end
  local hangingComp = self.owner:EnsureComponent(HangingComponent)
  local animConf = _G.DataConfigManager:GetAnimIdConf(action.anim_id, true)
  local animName = animConf and animConf.anim_name or nil
  local fromPos = self.owner:GetActorLocation()
  local AttachToTop = action.attach_to_top
  if AttachToTop > 0 then
    local offsetZ = hangingComp:GetHangingSocketOffsetZ()
    if AttachToTop < 20 then
      Target.Z = Target.Z - offsetZ
    else
      Target.Z = Target.Z - offsetZ
    end
  elseif AttachToTop < 0 then
    local Hit, success = UE4.UKismetSystemLibrary.Abs_LineTraceSingle(View, Target, Target - UE.FVector(0, 0, 200), UE4.ETraceTypeQuery.TraceTypeQuery_MAX, false, View)
    if success then
      Target.Z = Hit.ImpactPoint.Z + self.owner:GetScaledHalfHeight()
    end
  end
  LuaActionPlayZoomAnimation.UpdateMovementMode(self.owner, action.decreasing_curve)
  hangingComp:RequestDirectLerpMoving(animName, fromPos, Target, action.play_rate, action.blend_in_time, action.blend_out_time, action.decreasing_curve, action.loop_anim_name)
end

function ServerAIComponent:PlayVoice(action)
  if self.locked then
    return false
  end
  local animConf = _G.DataConfigManager:GetAnimIdConf(action.anim_id, true)
  local animName = animConf and animConf.anim_name or nil
  if animName then
    UE.URocoAIHelper.PlayAudioOnPawn(self.owner.viewObj, self.owner:GetPetbaseId() or 0, animName, action.voice_speed, action.high_priority)
  end
end

function ServerAIComponent:Launch(action)
  if self.locked then
    return false
  end
  if self.recording_move then
    self:RecordMove_Jump(action)
    return false
  end
  self.owner:Stop()
  local source = self.owner:GetActorLocation()
  local target = SceneUtils.ServerPos2ClientPos(action.jump_pos)
  local height = action.max_height
  local moveComp = self.owner.viewObj and self.owner.viewObj.CharacterMovement
  local gravity = moveComp and moveComp:GetGravityZ() or 980
  local launchVel = SceneUtils.CalcLaunchVelocity(source, target, height, gravity)
  if _G.GlobalConfig.DebugLuaBTree then
    UE.UKismetSystemLibrary.Abs_DrawDebugSphere(self.owner.viewObj, target, 10, 10, UE4.FLinearColor(1, 0, 0, 1), 10)
    UE.UKismetSystemLibrary.Abs_DrawDebugArrow(self.owner.viewObj, source, source + launchVel, 10, UE4.FLinearColor(1, 0, 0, 1), 10)
  end
  self.owner:LaunchCharacter(launchVel, true, true, true)
  return true
end

function ServerAIComponent:CancelLaunch(action)
  if not action.cancel_point then
    return true
  end
  local target = SceneUtils.ServerPos2ClientPos(action.cancel_point.pos)
  if self.locked then
    local pinnedPos = SceneUtils.GetPosInLand(target)
    if pinnedPos then
      self.owner:SetActorLocation(pinnedPos + UE.FVector(0, 0, self.owner:GetHalfHeight()))
    end
    return false
  end
  self.owner:Stop()
  local source = self.owner:GetActorLocation()
  if source:Dist2D(target) < 100 or source.Z < target.Z then
    return true
  end
  local moveComp = self.owner.viewObj and self.owner.viewObj.CharacterMovement
  local gravity = moveComp and moveComp:GetGravityZ() or 980
  local launchVel = SceneUtils.CalcLaunchVelocity(source, target, 0, gravity)
  if _G.GlobalConfig.DebugLuaBTree then
    UE.UKismetSystemLibrary.Abs_DrawDebugSphere(self.owner.viewObj, target, 10, 10, UE4.FLinearColor(0, 1, 0, 1), 10)
    UE.UKismetSystemLibrary.Abs_DrawDebugArrow(self.owner.viewObj, source, source + launchVel, 10, UE4.FLinearColor(0, 1, 0, 1), 10)
  end
  self.owner:LaunchCharacter(launchVel)
  return true
end

function ServerAIComponent:PlayRealtimeDialog(action)
  local DialogueConf = _G.DataConfigManager:GetDialogueConf(action.dialog_id, true)
  if DialogueConf then
    _G.NRCModuleManager:DoCmd(RealtimeDialogModuleCmd.StartRealtimeDialogByNpc, self.owner, DialogueConf)
  end
end

function ServerAIComponent:StopRealtimeDialog(action)
  _G.NRCModuleManager:DoCmd(RealtimeDialogModuleCmd.StopRealtimeDialogByNpc, self.owner)
end

function ServerAIComponent:StickTo(action)
  local snapComp = self.owner:EnsureComponent(SocketSnapComponent, true)
  local targetCharacter = self.owner.module:GetNpcByServerID(action.target_actor_id)
  targetCharacter = targetCharacter or _G.NRCModuleManager:DoCmd(_G.PlayerModuleCmd.GetPlayerByServerID, action.target_actor_id)
  if targetCharacter then
    snapComp:SetRelativeRotation(action.rotate.x, action.rotate.y, action.rotate.z)
    snapComp:GetRelativeTransformRef().Translation = UE.FVector(action.translate.x, action.translate.y, action.translate.z)
    snapComp:SnapTo(targetCharacter, action.self_socket, action.target_socket, action.stick_speed, action.stick_anim, true)
  end
end

function ServerAIComponent:FinishStickTo(action)
  local snapComp = self.owner:EnsureComponent(SocketSnapComponent)
  snapComp:CancelSnap()
end

function ServerAIComponent:SetNpcPos(action)
  local AIController = self.AIComp:GetControllerSafe()
  if not AIController then
    return
  end
  local FlowComp = AIController:GetComponentByClass(UE.URocoMultiposFlowComponent)
  if not FlowComp then
    return
  end
  FlowComp:AbortFollowing()
  local targetPos = SceneUtils.ServerPos2ClientPos(action.to_pos)
  FlowComp:ClearRoutes()
  FlowComp:AddMovePoint(targetPos, 0)
end

function ServerAIComponent:TryInteractNpc(action)
  local targetNpc = _G.NRCModuleManager:DoCmd(_G.NPCModuleCmd.GetNpcByServerID, action.interact_actor_id)
  local interactionComp = targetNpc and targetNpc.InteractionComponent
  if interactionComp then
    interactionComp:InteractWithNpc(self.owner)
  end
end

function ServerAIComponent:VelocityOrientRotation(action)
  if action.enable then
    local rot = action.rotation
    UE.URocoAIHelper.UpdateVelocityOrientRotation(self.owner.viewObj, true, rot.x, rot.y, rot.z)
  else
    UE.URocoAIHelper.UpdateVelocityOrientRotation(self.owner.viewObj, false, 0, 0, 0)
  end
end

function ServerAIComponent:WorldLaunchPlayer(action)
  local localPlayer = _G.NRCModuleManager:DoCmd(_G.PlayerModuleCmd.GET_LOCAL_PLAYER)
  local AttackedInteractionComp = localPlayer and localPlayer.playerAttackedInteractionComponent
  if AttackedInteractionComp and AttackedInteractionComp:CanLaunchByNpc() then
    local Direction = SceneUtils.ServerPos2ClientPos(action.direction)
    Direction.Z = 0
    Direction:Normalize()
    Direction:Mul(action.force_xy)
    Direction.Z = action.force_z
    AttackedInteractionComp:OnLaunchByNpc(self.owner, Direction, action.cool_down, true)
  end
end

function ServerAIComponent:ServerMove(action)
  if LegacyMove then
    return self:ServerMoveLegacy(action)
  end
  if self.recording_move then
    self:RecordMove_NavWalking(action)
    return false
  end
  if not action.to_pos_list or not action.to_time_list then
    Log.DebugFormat("[ServerAIComponent:ServerMove] action.to_pos_list \232\183\175\229\190\132\231\171\159\231\132\182\230\152\175\231\169\186\231\154\132, %s", self.owner:DebugNPCNameAndID())
    return false
  end
  if #action.to_pos_list ~= #action.to_time_list then
    Log.DebugFormat("[ServerAIComponent:ServerMove] action.to_pos_list(%d) and action.to_time_list(%d) \233\149\191\229\186\166\228\184\141\229\140\185\233\133\141, %s", #action.to_pos_list, #action.to_time_list, self.owner:DebugNPCNameAndID())
    return false
  end
  if self.owner.TurnComponent:IsTurning() then
    self.owner.TurnComponent:StopTurn(AIDefines.ActionResult.Aborted, true)
  end
  local AIController = self.AIComp:GetControllerSafe()
  if AIController then
    local FlowComp = AIController:GetComponentByClass(UE.URocoMultiposFlowComponent)
    if not FlowComp then
      self:LogFormatIfCritical("[ServerAIComponent:ServerMove] %s FlowComp is nil", self.owner.config.name)
      return false
    end
    FlowComp:AbortFollowing()
    FlowComp:SetFollowingType(UE.EMultiPosFollowingType.Direct)
    if action.accept_radius then
      FlowComp:SetAcceptanceRadius(action.accept_radius)
    end
    local bUseFirstTimeStamp = self.owner.IsMagicReplayActor and self.owner:IsMagicReplayActor() or false
    local CurrentTime = self:GetCurrentTime()
    if bUseFirstTimeStamp then
      local TimeDiff = CurrentTime - action.to_time_list[1]
      for idx = 1, #action.to_time_list do
        action.to_time_list[idx] = action.to_time_list[idx] + TimeDiff
      end
    end
    FlowComp:UpdateTimeStamp(CurrentTime)
    if action.move_mode then
      FlowComp:SetMoveMode(action.move_mode or 0, action.move_sub_mode or 0, action.height or 0, action.height_lerp_rate or 0)
    end
    local moveComp = self.owner.viewObj and self.owner.viewObj:GetMovementComponent()
    if moveComp then
      moveComp:SetOverridenMoveAnim(0, 0)
      moveComp.bCustomMoveBackward = action.is_backward or false
    end
    FlowComp:LuaAddMovePoints(action.to_pos_list, action.to_time_list)
    FlowComp.CompensatingAcceptRadius = 5
    if not self.locked then
      FlowComp:StartFollow()
    else
      self:LogFormatIfCritical("[ServerAIComponent:ServerMove] %s \230\131\179\232\166\129\231\167\187\229\138\168\239\188\140\228\189\134\230\152\175\232\162\171\233\148\129\228\189\143\228\186\134, %u", self.owner.config.name, self.owner.AIComponent.ForceLockFlag)
    end
    if GlobalConfig.DebugLuaBTree then
      Log.DebugFormat("MovePos|actor_id=%d|pos=(%d,%d,%d)", self.owner:GetServerId(), action.to_pos_list[1].x, action.to_pos_list[1].y, action.to_pos_list[1].z)
      self.MoveCache = action
      self._onsucc = AIController:AddDelegateListener(FlowComp.OnSuccess, self, self.OnMoveEnd)
      self._onfail = AIController:AddDelegateListener(FlowComp.OnFail, self, self.OnMoveEnd)
    end
  end
  return true
end

function ServerAIComponent:InterruptServerMove(action)
  if LegacyMove then
    return self:InterruptServerMoveLegacy(action)
  end
  local FinalPos = SceneUtils.ServerPos2ClientPos(action.interrupt_point.pos)
  local FlyComp = self.owner.BezierFlyComponent
  if FlyComp and FlyComp:IsFlying() then
    FlyComp:FinishFly(AIDefines.ActionResult.Aborted, FinalPos, not self.locked)
  end
  local AIController = self.owner.AIComponent.AIController
  if AIController and UE.UObject.IsValid(AIController) then
    local FlowComp = AIController:GetComponentByClass(UE.URocoMultiposFlowComponent)
    FlowComp:AbortFollowing(FinalPos, not self.locked)
  end
end

function ServerAIComponent:OnMoveEnd()
  self.MoveCache = nil
  local AIController = self.owner.AIComponent.AIController
  if AIController and UE.UObject.IsValid(AIController) then
    local FlowComp = AIController:GetComponentByClass(UE.URocoMultiposFlowComponent)
    AIController:RemoveDelegateListener(FlowComp.OnSuccess, self._onsucc)
    AIController:RemoveDelegateListener(FlowComp.OnFail, self._onfail)
  end
end

function ServerAIComponent:ServerMoveLegacy(action)
  if nil == action then
    return
  end
  if self.locked then
    Log.Warning("Locked but recieved ServerMove, Cached")
    self.isServerMoving = true
    self.cacheServerMoveReq = action
    self.currentSvrMoveIdx = 1
    return false
  end
  if AIDefines.UseCharacterReplicateMovementComponent then
    local nativeMovementComponent = self.owner.viewObj:GetMovementComponent()
    nativeMovementComponent.EnableReplicateMove = true
    local actor_id = self.owner.serverData.base.actor_id
    local localUE4 = _G.UE4
    local world = UE4Helper.GetCurrentWorld()
    for i = 1, #action.to_pos_list do
      local svrPos = action.to_pos_list[i]
      local svrDir = action.to_dir_list[i]
      local svrTime = action.to_time_list[i]
      local targetPos = SceneUtils.ServerPos2ClientPos(svrPos)
      local targetRot = SceneUtils.ServerDir2ClientRotator(svrDir)
      local navPoint, HitResult = localUE4.UNavigationSystemV1.Abs_K2_ProjectPointToNavigation(world, targetPos)
      navPoint = navPoint + UE4.FVector(0, 0, self.owner:GetScaledHalfHeight())
      if GlobalConfig.DebugLuaBTree then
        localUE4.UKismetSystemLibrary.Abs_DrawDebugSphere(world, navPoint, 10, 20, UE4.FLinearColor(0.5, 0.3, 0.2, 1), 10, 2)
      end
      nativeMovementComponent:ReplicateMoveData(navPoint, targetRot, action.move_mode, nil, nil, svrTime, actor_id)
    end
    return true
  end
  if self.isServerMoving then
    self.isServerMoving = false
    self:AbortServerMove()
  end
  self.isServerMoving = true
  self.cacheServerMoveReq = action
  self.currentSvrMoveIdx = 0
  self:DoNextSvrMove()
  local viewObj = self.owner.viewObj
  if viewObj then
    local moveCmp = viewObj:GetMovementComponent()
    if moveCmp then
      moveCmp:SetOverridenMoveAnim(action.move_mode)
    end
  end
  return true
end

function ServerAIComponent:InterruptServerMoveLegacy(action)
  if AIDefines.UseCharacterReplicateMovementComponent then
    self.owner:Stop()
    return true
  end
  if self.isServerMoving then
    local targetPos = SceneUtils.ServerPos2ClientPos(action.interrupt_point.pos)
    local selfPos = self.owner:GetActorLocation()
    local dist = UE4.UKismetMathLibrary.Vector_Distance2D(targetPos, selfPos)
    if dist < 50 then
      self:AbortServerMove()
      self.owner:Stop()
    else
      self.cacheServerMoveReq.to_time_list = {
        [1] = action.cur_time
      }
      self.cacheServerMoveReq.to_pos_list = {
        [1] = action.interrupt_point.pos
      }
      self.currentSvrMoveTargetPoint = targetPos
      self.currentSvrMoveIdx = 1
      if not self.locked then
        self:DoNextSvrMove(true)
      end
    end
  end
  return true
end

function ServerAIComponent:TurnTo(action, time_over)
  if self.locked then
    return false
  end
  local SkillComp = self.owner.WorldCombatSkillComponent
  local bIsPlayingSkill = SkillComp and SkillComp.currentContext ~= nil
  if bIsPlayingSkill then
    Log.Debug("ServerAIComponent:TurnTo Block!", self.owner:GetServerId())
    return false
  end
  local oriRotation = self.owner:GetActorRotation()
  local p = action.turn_pos
  local turnPosVector = UE4.FVector(p.x, p.y, p.z)
  local targetRotation = UE4.UKismetMathLibrary.FindLookAtRotation(self.owner:GetActorLocation(), turnPosVector)
  if time_over > 1000 then
    self:SetCacheRotation(targetRotation.Yaw)
    return true
  end
  local speed = action.turn_speed
  local time = 0
  if speed and speed > 0 then
    local Target, Now, Delta = LuaMathUtils.DiffAngle(oriRotation.Yaw or 0, targetRotation.Yaw or 0)
    time = math.abs(Delta) / speed
    time = math.clamp(time, 0.1, 2)
  else
    targetRotation.Pitch = 0
    targetRotation.Roll = 0
    self.owner:SetActorRotation(targetRotation)
    self:OnTurnEnd()
    return true
  end
  local timingMethod = action.use_anim_length
  local animRate = action.anim_speed_scale
  if 0 == animRate then
    animRate = 1
  end
  self.turning = true
  self.owner.TurnComponent:StartTurn_S(targetRotation.Yaw, time, true, timingMethod, animRate, self, self.OnTurnEnd)
  return true
end

function ServerAIComponent:OnTurnEnd()
  self.turning = false
end

function ServerAIComponent:CancelTurnTo(action)
  if self.turning then
    self.owner.TurnComponent:StopTurn(true)
  end
  return true
end

function ServerAIComponent:WorldAttack(action, time_over)
  if self.locked then
    return false
  end
  if time_over > 1000 then
    return true
  end
  local AttackComp = self.owner:EnsureComponent(AttackComponent)
  if AttackComp then
    local param = AttackComponent.CreateParam()
    param.AimType = action.aim_type
    param.ActionType = action.attack_type
    local player = _G.NRCModeManager:DoCmd(_G.PlayerModuleCmd.GetPlayerByServerID, action.target_actor_id)
    if not player then
      Log.DebugFormat("[ServerWorldAttack] TargetPlayer is out of scope, discard. s=%d, p=%d", self.owner:GetServerId(), action.target_actor_id)
      return true
    end
    param.Target = player
    param.Radius = action.range
    param.Predict = action.predict
    if GlobalConfig.DisablePetDamage then
      param.Damage = 0
    else
      param.Damage = action.damage
    end
    param.HitStrength = action.hit_strength
    param.PlayerHitType = action.hit_perform_type
    param.TargetPos = action.use_specific_pos and action.specific_pos and SceneUtils.ServerPos2ClientPos(action.specific_pos)
    param.AbnormalStatus = action.abnormal_type
    param.AbnormalDuration = action.abnormal_duration
    AttackComp:StartAttack(param)
  end
  return true
end

function ServerAIComponent:StopWorldAttack(action)
  if self.owner.AttackComponent then
    self.owner.AttackComponent:StopAttack(true)
  end
  return true
end

local HIDDEN_FLAG = 4

function ServerAIComponent:PlayPerceptionEffect(action, time_over)
  if self.locked or time_over > 1000 then
    return false
  end
  local otherHiddenFlags = self.owner.hiddenFlag & ~(1 << HIDDEN_FLAG)
  if otherHiddenFlags > 0 then
    return true
  end
  local view = self.owner.viewObj
  if view and UE.UObject.IsValid(view) then
    local skillPath = _G.UEPath.NPC_PERCEPT_EFFECT[action.effect_id]
    local skillComp = view:GetComponentByClass(UE4.URocoSkillComponent)
    if skillComp then
      local skillProxy = RocoSkillProxy.Create(skillPath, skillComp, _G.PriorityEnum.Passive_World_AI_Server_SkillRes)
      if skillProxy then
        skillProxy:SetCaster(view)
        skillProxy:SetPassive(true)
        skillProxy:PlaySkill()
      end
    end
  end
  return true
end

function ServerAIComponent:PlayPerceptionHud(action)
  local petHud = self.owner.PetHUDComponent
  if petHud then
    local level = action.hud_type
    if level == Enum.PerceptionHudType.PHT_TACK_ACTION then
      local player = NRCModuleManager:DoCmd(PlayerModuleCmd.GET_LOCAL_PLAYER)
      if action.show_range and action.show_range > 0 then
        local playerLoc = player:GetActorLocationFrameCache()
        local selfLoc = self.owner:GetActorLocation()
        local dist = UE.FVector.Dist(playerLoc, selfLoc)
        if dist > action.show_range then
          level = 0
        end
      elseif action.local_player_obj_id ~= player.serverData.base.actor_id then
        level = 0
      end
    end
    if not action.is_show then
      Log.DebugFormat("[ServerAIComponent:PlayPerceptionHud] %s not_show type=%d, target=%u", self.owner.config.name, level, action.target_actor_id)
      level = 0
    else
      Log.DebugFormat("[ServerAIComponent:PlayPerceptionHud] %s type=%d, target=%u", self.owner.config.name, level, action.target_actor_id)
    end
    if 4 == level then
      local applied = petHud:SetPerceptionTargetingNpcById(action.target_actor_id)
      if not applied or 0 == action.target_actor_id then
        level = 1
      end
    else
      petHud:SetPerceptionTargetingNpcById(0)
    end
    self.owner.PetHUDComponent:SetMainHudPerception(level)
  end
  return true
end

function ServerAIComponent:PerceivePlayer(action)
  self.owner.AIComponent:PerceiveLocalPlayer(action.is_perceive)
end

function ServerAIComponent:PlayChatBubble(action)
  if string.IsNilOrEmpty(action.message_str) then
    return true
  end
  if self.locked then
    return false
  end
  local npc = self.owner
  if npc:IsHidden() and not npc:IsHidden(NPCModuleEnum.NpcReasonFlags.HIDDEN) then
    return self:Finish(true)
  end
  local view = npc.viewObj
  if view then
    local FriendModule = _G.NRCModuleManager:GetModule("FriendModule")
    if FriendModule then
      if FriendModule:IsEmo(action.message_str) then
        local Path = FriendModule:OnCmdGetEmoPathByEsc(action.message_str)
        FriendModule.chatBubbleController:AddEmojiBubble(Path, view, action.play_time)
      else
        FriendModule.chatBubbleController:AddTextBubble(action.message_str, UE4.UNRCStatics.HexToSlateColor("#ffffff"), _G.NRCBigWorldPreloader:Get("Font_Obj_FangZhengLanTing_ZhongChu"), false, view, action.play_time)
      end
    end
  end
end

function ServerAIComponent:ServerAttach(action)
  self.owner:SetNPCGravity(0)
  local Model = self.owner.viewObj
  if Model then
    if action.allow_rotate then
      Model:SetBpRotateRate(UE4.FRotator(action.rotate_speed, action.rotate_speed, action.rotate_speed))
      Model:LerpToRotation(UE4.FRotator(action.attach_dir.x, action.attach_dir.y, action.attach_dir.z))
    end
    local moveComp = Model:GetMovementComponent()
    if moveComp then
      moveComp:SetMovementMode(UE4.EMovementMode.MOVE_None)
    end
  end
  local Pos = SceneUtils.ServerPos2ClientPos(action.attach_pos)
  self.activeAttachParam = nil
  self.isServerAttaching = false
  if 0 == action.move_speed then
    self.owner:SetActorLocation(Pos)
  else
    self.activeAttachParam = {
      speed = action.move_speed,
      pos = Pos
    }
    self.isServerAttaching = true
  end
end

function ServerAIComponent:CancelServerAttach(action)
  self.owner:SetNPCGravity(1)
  local Model = self.owner.viewObj
  if Model then
    Model:LerpToRotation(UE4.FRotator(0, self.owner:GetActorRotation().Yaw, 0))
    local moveComp = Model:GetMovementComponent()
    moveComp:SetMovementMode(UE4.EMovementMode.MOVE_Falling)
  end
  local Pos = SceneUtils.ServerPos2ClientPos(action.cancel_point)
  self.owner:SetActorLocation(Pos)
end

function ServerAIComponent:UpdateTransform(DeltaTime)
  if 0 == self.activeAttachParam.speed then
    self.owner:SetActorLocation(self.activeAttachParam.pos)
    self.activeAttachParam = nil
    self.isServerAttaching = false
    return
  end
  local selfPos = self.owner:GetActorLocation()
  local dir = self.activeAttachParam.pos - selfPos
  local dist = dir:Size()
  if dist < 10 then
    self.activeAttachParam = nil
    self.isServerAttaching = false
    return
  end
  dir:Normalize()
  local ratio = math.min(dist, DeltaTime * self.activeAttachParam.speed)
  dir = dir * ratio
  dir = dir + selfPos
  self.owner:SetActorLocation(dir)
end

local LocalSpawnTransformObj = UE.FTransform()
local LocalTargetClass = UE.ANPCSimpleSkillTarget

function ServerAIComponent:OnPersistAnimationTimer()
  if self.owner and self.currentPersistAnimName then
    self.owner:StopAnim(self.currentPersistAnimName)
    self.currentPersistAnimName = nil
  end
end

function ServerAIComponent:IsHoldOnEndAnimation(animName)
  if not animName then
    return false
  end
  for _, persistAnimName in ipairs(ServerAIComponent.HoldOnEndAnimationNames) do
    if persistAnimName == animName then
      return true
    end
  end
  return false
end

function ServerAIComponent:PlaySkill(action, over_time)
  if self.locked then
    return false
  end
  if over_time > 1000 then
    self:CacheSkill(action)
    return false
  end
  local skillPath = action.skill_path
  if not skillPath or "" == skillPath then
    Log.PrintScreenMsg("[ServerAIComponent:PlaySkill] skill_path is empty, skill_id=%s", tostring(action.skill_id))
    return false
  end
  local view = self.owner.viewObj
  local targetView, targetPos
  if action.target_id and 0 ~= action.target_id then
    local targetCharacter, isPlayer = SceneUtils.GetActorByServerId(action.target_id)
    targetView = targetCharacter and targetCharacter.viewObj
    if not targetView or not targetView:IsValid() then
      self:OnSkillEnd(skillPath)
      return true
    end
  elseif action.use_specific_pos and action.specific_pos then
    targetPos = SceneUtils.ServerPos2ClientPos(action.specific_pos)
  end
  if view and UE.UObject.IsValid(view) then
    local skillConf = _G.DataConfigManager:GetNrcAiPerformSkillConf(action.skill_id or 0, true)
    local passive = skillConf and skillConf.parallel_playback or false
    local interrupt_when_stop_ai = skillConf and skillConf.interrupt_when_stop_ai or false
    local skillComp = view:GetComponentByClass(UE.URocoSkillComponent)
    if skillComp then
      local existingProxy = self.skillProxyMap[skillPath]
      if existingProxy then
        self.skillProxyMap[skillPath] = nil
        existingProxy:CancelSkill(UE.ESkillActionResult.SkillActionResultInterrupted)
        existingProxy:Destroy()
      end
      local skillProxy = RocoSkillProxy.Create(skillPath, skillComp, _G.PriorityEnum.Passive_World_AI_Server_SkillRes)
      if skillProxy then
        skillProxy:SetCaster(view)
        if targetView then
          skillProxy:SetTargets({targetView})
        end
        skillProxy:RegisterEventCallback("End", self, function(this, name, skillObj)
          this:OnSkillEnd(skillPath)
        end):RegisterEventCallback("PreEnd", self, function(this, name, skillObj)
          this:OnSkillEnd(skillPath)
        end):RegisterEventCallback("Interrupt", self, function(this, name, skillObj)
          this:OnSkillEnd(skillPath)
        end)
        if not targetView and targetPos then
          local function SetupSkillTarget(this, name, skillObj)
            LocalSpawnTransformObj.Translation = targetPos
            
            local TargetObj = view:GetWorld():Abs_SpawnActor(LocalTargetClass, LocalSpawnTransformObj, UE4.ESpawnActorCollisionHandlingMethod.AlwaysSpawn)
            skillObj:SetTargets({TargetObj})
            skillObj:GetBlackboard():SetValueAsObject("AI_TargetObj", TargetObj)
          end
          
          skillProxy:RegisterEventCallback("PreStart", self, SetupSkillTarget)
        end
        skillProxy:SetPassive(passive)
        skillProxy:PlaySkill()
        self.skillProxyMap[skillPath] = skillProxy
        self.skillInterruptFlagMap[skillPath] = interrupt_when_stop_ai
        if interrupt_when_stop_ai and self.AIComp and not self._forceLockRegistered then
          self._forceLockRegistered = true
          self.AIComp:RegisterForceLockChanged(self, self.OnAILockChanged)
        end
        return true
      end
    end
  end
  self:OnSkillEnd(skillPath)
  return true
end

function ServerAIComponent:OnAILockChanged(lock)
  if lock then
    local toInterrupt = {}
    for path, flag in pairs(self.skillInterruptFlagMap) do
      if flag then
        toInterrupt[#toInterrupt + 1] = path
      end
    end
    for _, path in ipairs(toInterrupt) do
      local proxy = self.skillProxyMap[path]
      if proxy then
        self.skillProxyMap[path] = nil
        self.skillInterruptFlagMap[path] = nil
        proxy:CancelSkill(UE.ESkillActionResult.SkillActionResultInterrupted)
        proxy:Destroy()
      end
    end
    self:_TryUnregisterForceLock()
  end
end

function ServerAIComponent:OnSkillEnd(skillPath)
  if skillPath then
    self.skillProxyMap[skillPath] = nil
    self.skillInterruptFlagMap[skillPath] = nil
  end
  self:_TryUnregisterForceLock()
  if self.reportPositionAfterNextSkill and self.owner and not next(self.skillProxyMap) then
    self.owner:ReportPosition(_G.ProtoEnum.SetNpcPosType.SNPT_AI_MOVE)
    self.reportPositionAfterNextSkill = false
  end
end

function ServerAIComponent:_TryUnregisterForceLock()
  if not self._forceLockRegistered then
    return
  end
  for _, flag in pairs(self.skillInterruptFlagMap) do
    if flag then
      return
    end
  end
  self._forceLockRegistered = false
  if self.AIComp then
    self.AIComp:UnRegisterForceLockChanged(self, self.OnAILockChanged)
  end
end

function ServerAIComponent:_CleanAllSkillProxies(destroyProxy)
  if self._forceLockRegistered and self.AIComp then
    self._forceLockRegistered = false
    self.AIComp:UnRegisterForceLockChanged(self, self.OnAILockChanged)
  end
  for path, proxy in pairs(self.skillProxyMap) do
    self.skillProxyMap[path] = nil
    proxy:CancelSkill(UE.ESkillActionResult.SkillActionResultInterrupted)
    if destroyProxy then
      proxy:Destroy()
    end
  end
  self.skillInterruptFlagMap = {}
end

function ServerAIComponent:StopSkill(action)
  self:CacheSkill(nil)
  local skillPath = action.skill_path
  if not skillPath or "" == skillPath then
    self:_CleanAllSkillProxies(true)
    if self.reportPositionAfterNextSkill and self.owner then
      self.owner:ReportPosition(_G.ProtoEnum.SetNpcPosType.SNPT_AI_MOVE)
      self.reportPositionAfterNextSkill = false
    end
    return true
  end
  local proxy = self.skillProxyMap[skillPath]
  if not proxy then
    return false
  end
  self.skillProxyMap[skillPath] = nil
  self.skillInterruptFlagMap[skillPath] = nil
  self:_TryUnregisterForceLock()
  if self.reportPositionAfterNextSkill and not next(self.skillProxyMap) and self.owner then
    self.owner:ReportPosition(_G.ProtoEnum.SetNpcPosType.SNPT_AI_MOVE)
    self.reportPositionAfterNextSkill = false
  end
  proxy:CancelSkill(UE.ESkillActionResult.SkillActionResultInterrupted)
  proxy:Destroy()
  return true
end

function ServerAIComponent:CollisionCancelRecover(action)
end

function ServerAIComponent:WorldHidden(action)
  self.hideState = true
  if self.UpdatingHideState then
    return
  end
  if self.locked then
    return
  end
  local hidComp = self.owner.HiddenComponent
  if hidComp then
    local player = _G.NRCModeManager:DoCmd(_G.PlayerModuleCmd.GetPlayerByServerID, action.target_actor_id)
    hidComp:SetPlayerContext(player)
    if hidComp.state == HiddenComponent.State.PendingEnd then
      hidComp.endingDelegates:Add(self, self.UpdateHideState)
    else
      hidComp:RegisterEnteringDelegate(self, function(this, result)
        if not AIDefines.ActionResult.Ok(result) then
          self:UpdateHideState()
        end
      end)
      hidComp:BeginHide()
    end
  end
  if GlobalConfig.DebugLuaBTree then
    local npc = self.owner
    local world = UE4Helper.GetCurrentWorld()
    UE4.UKismetSystemLibrary.Abs_DrawDebugSphere(world, npc:GetActorLocation() + UE4.FVector(0, 0, 80), 10, 20, UE4.FLinearColor(0.2, 0.5, 0.5, 1), 10, 2)
    UE4.UKismetSystemLibrary.Abs_DrawDebugString(world, npc:GetActorLocation() + UE4.FVector(0, 0, 80), "Hidden", nil, UE4.FLinearColor(0.2, 0.5, 0.5, 1), 10)
  end
end

function ServerAIComponent:WorldUnhidden(action)
  self.hideState = false
  if self.UpdatingHideState then
    return
  end
  if self.locked then
    return
  end
  local hidComp = self.owner.HiddenComponent
  if hidComp then
    if hidComp.state == HiddenComponent.State.PendingStart then
      hidComp.enteringDelegates:Add(self, self.UpdateHideState)
    else
      hidComp:EndHide(self, function(this, result)
        if not AIDefines.ActionResult.Ok(result) then
          self:UpdateHideState()
        end
      end)
    end
  end
  if GlobalConfig.DebugLuaBTree then
    local npc = self.owner
    local world = UE4Helper.GetCurrentWorld()
    UE4.UKismetSystemLibrary.Abs_DrawDebugSphere(world, npc:GetActorLocation() + UE4.FVector(0, 0, 80), 10, 20, UE4.FLinearColor(0.2, 0.5, 0.5, 1), 10, 2)
    UE4.UKismetSystemLibrary.Abs_DrawDebugString(world, npc:GetActorLocation() + UE4.FVector(0, 0, 80), "Unhidden", nil, UE4.FLinearColor(0.2, 0.5, 0.5, 1), 10)
  end
end

function ServerAIComponent:UpdateHideState()
  self.UpdatingHideState = true
  a.task(function()
    a.wait(au.DelayFrames(1))
    if not self.owner or self.locked then
      return
    end
    local hidComp = self.owner.HiddenComponent
    if hidComp then
      if self.hideState then
        hidComp:SetHide()
      else
        hidComp:ResetHide(true, false)
      end
    end
    self.UpdatingHideState = false
  end)()
end

function ServerAIComponent:LookAt(action)
  if action.enable then
    local target = _G.NRCModuleManager:DoCmd(_G.PlayerModuleCmd.GetPlayerByServerID, action.target_actor_id)
    if nil == target then
      target = self.owner.module:GetNpcByServerID(action.target_actor_id)
    end
    if action.at_camera then
      self.owner.AIComponent:TryAppendState(AIStateLookAtCamera, action.immediately, target and target.viewObj)
    elseif nil ~= target then
      self.owner:SetHeadLookAtActor(target.viewObj, action.immediately)
      return
    end
  else
    self.owner.AIComponent:TryRemoveState(AIStateLookAtCamera)
    self.owner:SetHeadLookAtActor(nil, action.immediately)
  end
end

function ServerAIComponent:TickServerMove(deltaTime)
  do return end
  local SkillComp = self.owner.WorldCombatSkillComponent
  local bIsPlayingSkill = SkillComp and SkillComp.currentContext ~= nil
  if bIsPlayingSkill then
    Log.Warning("ServerAIComponent:TickServerMove Blocked!", self.owner:GetServerId())
    return
  end
  if deltaTime > 0.1 then
    self:SetCacheLocation(self.currentSvrMoveTargetPoint)
    self:SetCacheRotation(self.cacheServerMoveReq.to_dir_list[self.currentSvrMoveIdx])
  end
  local hasReach = self:HasReachedSvrMoveTarget()
  if hasReach then
    self:OnSvrMoveReachedOnePoint()
    return
  end
  if self.currentSvrMoveIdx <= #self.cacheServerMoveReq.to_time_list then
    local nextTime = self.cacheServerMoveReq.to_time_list[self.currentSvrMoveIdx]
    local nextTimeDelta = _G.ZoneServer:GetServerTime() - self.timeCompensation - nextTime
    if nextTimeDelta > 0 then
      if nil == nextTime then
        Log.Dump(self.cacheServerMoveReq.to_time_list)
      end
      if self:DoNextSvrMove() then
      else
        self.timeCompensation = _G.ZoneServer:GetServerTime() - self.cacheServerMoveReq.to_time_list[self.currentSvrMoveIdx]
        self.timeCompensation = math.min(self.timeCompensation, 100)
      end
    end
  end
  local viewObj = self.owner.viewObj
  if nil == viewObj then
    return
  end
  local moveCmp = viewObj:GetMovementComponent()
  if nil == moveCmp then
    return
  end
  local currentLocation = self.owner:GetActorLocation()
  local inputVector = self.currentSvrMoveTargetPoint - currentLocation
  local velocity = inputVector
  moveCmp:LuaRequestDirectMove(velocity, true)
  local duration = self.cacheServerMoveReq.to_time_list[self.currentSvrMoveIdx] - _G.ZoneServer:GetServerTime()
  duration = math.max(duration, 0.1)
  local expectedSpeed = inputVector:Size() / duration * 1000
  local subSpeed = expectedSpeed - moveCmp.Velocity:Size()
  if math.abs(subSpeed) > 1 then
    moveCmp.ServerMoveSpeedExtra = math.clamp(subSpeed, -100, 100)
  else
    moveCmp.ServerMoveSpeedExtra = 0
  end
end

function ServerAIComponent:AbortServerMove()
  if self.isServerMoving then
    self.isServerMoving = false
    self:CleanSvrMoveData()
  end
end

function ServerAIComponent:CleanSvrMoveData()
  self.cacheServerMoveReq = nil
  self.currentSvrMoveIdx = 1
  self.currentSvrMoveTargetPoint = nil
  local viewObj = self.owner.viewObj
  if viewObj then
    local moveCmp = viewObj:GetMovementComponent()
    if moveCmp then
      moveCmp.ServerMoveSpeedExtra = 0
    end
  end
end

function ServerAIComponent:HasReachedSvrMoveTarget(distThreshold)
  distThreshold = distThreshold or 30
  local point_ = self.cacheServerMoveReq.to_pos_list[self.currentSvrMoveIdx]
  local point = SceneUtils.ServerPos2ClientPos(point_)
  local actorLocation = self._cachedLocation or self.owner:GetActorLocation()
  local actorForward = self.owner:GetForwardVector()
  if self.currentSvrMoveIdx > 1 then
    local Dir = point - actorLocation
    Dir:Normalize()
    if actorForward:Dot(Dir) < 0 then
      return true
    end
  end
  if distThreshold > point:Dist2D(actorLocation) then
    return true
  end
  return false
end

function ServerAIComponent:DesiredServerMoveIdx(currentTime)
  local point_count = #self.cacheServerMoveReq.to_time_list
  local begin_idx = 0 ~= self.currentSvrMoveIdx and self.currentSvrMoveIdx or 1
  if point_count > begin_idx then
    for i = begin_idx, point_count do
      if currentTime < self.cacheServerMoveReq.to_time_list[i] then
        return i
      end
    end
  end
  return point_count
end

function ServerAIComponent:DoNextSvrMove(resume)
  resume = resume or false
  if self.isServerMoving then
    local lastIdx = self.currentSvrMoveIdx
    if self.cacheServerMoveReq == nil then
      return false
    end
    if not resume then
      local DesiredIdx = self:DesiredServerMoveIdx(self:GetCurrentTime())
      if DesiredIdx > self.currentSvrMoveIdx then
        self.currentSvrMoveIdx = DesiredIdx
      else
        self.currentSvrMoveIdx = self.currentSvrMoveIdx + 1
      end
    end
    local nextPosition = self.cacheServerMoveReq.to_pos_list[self.currentSvrMoveIdx]
    local nextTimestamp = self.cacheServerMoveReq.to_time_list[self.currentSvrMoveIdx]
    if nil ~= nextPosition then
      local vectorPos = SceneUtils.ServerPos2ClientPos(nextPosition)
      local succeedPos, bSucceed = self.owner.module:GetPosInNav(vectorPos, 100, 2000)
      if bSucceed then
        self.currentSvrMoveTargetPoint = succeedPos
      else
        self.currentSvrMoveTargetPoint = vectorPos
        Log.WarningFormat("[ServerAI] NextMove Nav failed at point(%u) %d of %d, at %s", nextTimestamp, self.currentSvrMoveIdx, #self.cacheServerMoveReq.to_pos_list, tostring(self.currentSvrMoveTargetPoint))
      end
      return true
    end
    self.currentSvrMoveIdx = lastIdx
  end
  return false
end

function ServerAIComponent:OnSvrMoveReachedOnePoint()
  if self.isServerMoving then
    local hasNext = self:DoNextSvrMove()
    if not hasNext then
      self.isServerMoving = false
      self:CleanSvrMoveData()
    end
  end
end

function ServerAIComponent:PauseMove()
  local AIController = self.owner and self.owner.AIComponent.AIController
  if AIController and UE.UObject.IsValid(AIController) then
    local FlowComp = AIController:GetComponentByClass(UE.URocoMultiposFlowComponent)
    if FlowComp then
      FlowComp:PauseMove()
    end
  end
end

function ServerAIComponent:ResumeMove()
  local AIController = self.owner and self.owner.AIComponent.AIController
  if AIController and UE.UObject.IsValid(AIController) then
    local FlowComp = AIController:GetComponentByClass(UE.URocoMultiposFlowComponent)
    if FlowComp then
      FlowComp:UpdateTimeStamp(self:GetCurrentTime())
      FlowComp:ResumeMove()
    end
  end
end

local VecCached = UE.FVector()

function ServerAIComponent:ServerFly(action, time_over)
  if time_over and time_over > 1000 then
    return false
  end
  if self.recording_move then
    self:RecordMove_BezierFly(action)
    return false
  end
  local BuffComp = self.owner.WorldCombatBuffComponent
  if BuffComp and BuffComp:HasBuffOfType(Enum.WorldBuffEffect.WBE_STUN) then
    Log.DebugFormat("[OnNpcServerFly] Can't fly when npc is stunned, npc: %s", self.owner.config.name)
    return false
  end
  if not action.to_pos_list or 0 == #action.to_pos_list then
    Log.DebugFormat("[ServerAIComponent:ServerFly] to_pos_list is nil or empty, npc:%s", self.owner.config.name)
    return false
  end
  if not action.to_timestamp_list or 0 == #action.to_timestamp_list then
    Log.DebugFormat("[ServerAIComponent:ServerFly] to_timestamp_list is nil or empty, npc:%s", self.owner.config.name)
    action.to_timestamp_list = {}
    for i = 1, #action.to_pos_list do
      action.to_timestamp_list[i] = 0
    end
  end
  local flyComp = self.owner:EnsureComponent(BezierFlyComponent)
  if flyComp then
    flyComp.speedBase = action.fly_speed
    local cur_dir
    if action.cur_dir then
      cur_dir = SceneUtils.ServerPos2ClientPos(action.cur_dir)
    else
      cur_dir = self.owner:GetForwardVector()
    end
    local view = self.owner.viewObj
    local moveComp = view and view:GetComponentByClass(UE.UCharacterNavMovementComponent)
    if moveComp then
      moveComp.MaxFlySpeed = action.fly_speed
    end
    flyComp:ContinuousFly(true)
    local AIController = self.owner and self.owner.AIComponent.AIController
    if AIController and UE.UObject.IsValid(AIController) then
      local FlowComp = AIController:GetComponentByClass(UE.URocoMultiposFlowComponent)
      if not FlowComp then
        Log.DebugFormat("[ServerAIComponent:ServerFly] FlowComp is nil, npc:%s", self.owner and self.owner.config.name or "unknown")
        return false
      end
      if self.locked then
        SceneUtils.ServerPos2ClientPosInPlace(action.to_pos_list[#action.to_pos_list], 1.0, VecCached)
        FlowComp:AddMovePoint(VecCached, action.to_timestamp_list[#action.to_timestamp_list])
        return false
      end
      FlowComp:AbortFollowing()
      FlowComp:SetFollowingType(UE.EMultiPosFollowingType.Direct)
      local bUseFirstTimeStamp = self.owner.IsMagicReplayActor and self.owner:IsMagicReplayActor() or false
      local CurrentTime = self:GetCurrentTime()
      if bUseFirstTimeStamp then
        local TimeDiff = CurrentTime - action.to_timestamp_list[1] + 2000
        for idx = 1, #action.to_timestamp_list do
          action.to_timestamp_list[idx] = action.to_timestamp_list[idx] + TimeDiff
        end
      end
      FlowComp:UpdateTimeStamp(CurrentTime)
      local halfHeight = self.owner:GetScaledHalfHeight()
      local to_pos_list = action.to_pos_list
      for i = 1, #action.to_pos_list do
        to_pos_list[i].z = to_pos_list[i].z + halfHeight
      end
      flyComp:StartFlyWithPoints(cur_dir, action.to_pos_list, action.to_timestamp_list)
    end
    if GlobalConfig.DebugLuaBTree then
      local world = UE4Helper.GetCurrentWorld()
      for i = 1, #action.to_pos_list do
        local server_pos = SceneUtils.ServerPos2ClientPos(action.to_pos_list[i])
        UE.UKismetSystemLibrary.Abs_DrawDebugSphere(world, server_pos, 10, 20, UE.FLinearColor(0.5, 0.3, 0.2, 1), 10, 2)
      end
    end
  else
    Log.DebugFormat("[OnNpcServerFly] Can't find FlyComp when server fly, npc: %s", self.owner.config.name)
  end
end

function ServerAIComponent:SetCacheLocation(pos)
  self._cachedLocation = pos
  self.applyTransformCurrentFrame = true
end

function ServerAIComponent:SetCacheRotation(yaw)
  self._cachedRotation = yaw
  self.applyTransformCurrentFrame = true
end

function ServerAIComponent:CacheSkill(action)
  self._cachedSkill = action
end

function ServerAIComponent:OnApplyTransform()
  if self.applyTransformCurrentFrame then
    if self._cachedLocation then
      self.owner:SetActorLocation(self._cachedLocation + UE4Helper.UpVector * self.owner:GetScaledHalfHeight())
      self._cachedLocation = nil
    end
    if self._cachedRotation then
      self.owner:SetActorRotation(UE.FRotator(0, self._cachedRotation, 0))
      self._cachedRotation = nil
    end
    if self._cachedSkill then
      self:PlaySkill(self._cachedSkill, 0)
      self._cachedSkill = nil
    end
    self.applyTransformCurrentFrame = false
  end
end

function ServerAIComponent:LogFormatIfCritical(...)
  if self.critical then
    Log.DebugFormat(...)
  end
end

function ServerAIComponent:EnsureInitMoveInfo()
  if not self.init_move_info then
    self.init_move_info = {
      move_mode = nil,
      nav_move_info = nil,
      bezier_fly_info = nil,
      jump_info = nil,
      turn_to_info = nil,
      stick_to_info = nil
    }
  end
  return self.init_move_info
end

function ServerAIComponent:RecordMove_NavWalking(action)
  local init_move_info = self:EnsureInitMoveInfo()
  init_move_info.bezier_fly_info = nil
  init_move_info.jump_info = nil
  init_move_info.turn_to_info = nil
  init_move_info.nav_move_info = {
    to_pos_list = action.to_pos_list,
    to_time_list = action.to_time_list,
    accept_radius = action.accept_radius,
    is_backward = action.is_backward
  }
end

function ServerAIComponent:RecordMove_BezierFly(action)
  local init_move_info = self:EnsureInitMoveInfo()
  init_move_info.nav_move_info = nil
  init_move_info.jump_info = nil
  init_move_info.turn_to_info = nil
  init_move_info.bezier_fly_info = {
    fly_speed = action.fly_speed,
    to_pos_list = action.to_pos_list,
    to_time_list = action.to_timestamp_list
  }
end

function ServerAIComponent:RecordMove_Jump(action)
  local init_move_info = self:EnsureInitMoveInfo()
  init_move_info.nav_move_info = nil
  init_move_info.bezier_fly_info = nil
  init_move_info.turn_to_info = nil
  init_move_info.jump_info = {
    jump_pos = action.jump_pos,
    max_height = action.max_height,
    begin_pos = action.begin_pos
  }
end

function ServerAIComponent:EvalMovePosAndSet()
  if not self.recording_move then
    return
  end
  if not self.AIComp:IsControllerValid() then
    return
  end
  self.recording_move = false
  if not self.init_move_info then
    self:InitMove_PinOnGround()
    return
  end
  if self.init_move_info.nav_move_info then
    self:InitMove_NavWalking(self.init_move_info.nav_move_info)
  elseif self.init_move_info.bezier_fly_info then
    self:InitMove_BezierFly(self.init_move_info.bezier_fly_info)
  elseif self.init_move_info.jump_info then
    self:InitMove_Jump(self.init_move_info.jump_info)
  end
end

function ServerAIComponent:InitMove_PinOnGround(pos)
  local currentLocation = self.owner:GetActorLocation()
  if not pos then
    local ServerData = self.owner.serverData
    pos = ServerData.base.pt.pos
  end
  local target = SceneUtils.ServerPos2ClientPos(pos)
  local halfHeight = self.owner:GetHalfHeight()
  local pinnedPos = SceneUtils.GetPosInLand(target, halfHeight, 2 * halfHeight)
  if pinnedPos and pinnedPos.Z > currentLocation.Z then
    if self.owner.IsMagicReplayActor and self.owner:IsMagicReplayActor() and self:OwnerResourceLoaded() then
      return
    end
    self.owner:SetActorLocation(pinnedPos)
  end
end

function ServerAIComponent:InitMove_NavWalking(nav_move_info)
  if not self:OwnerResourceLoaded() then
    local to_pos_list = nav_move_info.to_pos_list
    local to_time_list = nav_move_info.to_time_list
    local currentTime = ZoneServer:GetServerTime()
    local currentIndex
    if to_time_list then
      for i = 1, #to_time_list do
        if currentTime >= to_time_list[i] then
          currentIndex = i
        end
      end
    end
    if currentIndex and to_pos_list and to_pos_list[currentIndex] then
      self:InitMove_PinOnGround(to_pos_list[currentIndex])
    end
  end
  self:ServerMove(nav_move_info)
end

function ServerAIComponent:InitMove_BezierFly(bezier_fly_info)
  if not self:OwnerResourceLoaded() then
    local to_pos_list = bezier_fly_info.to_pos_list
    local to_time_list = bezier_fly_info.to_timestamp_list
    local currentTime = ZoneServer:GetServerTime()
    local currentIndex
    if to_time_list then
      for i = 1, #to_time_list do
        if currentTime >= to_time_list[i] then
          currentIndex = i
        end
      end
    end
    if currentIndex and to_pos_list and to_pos_list[currentIndex] then
      self.owner:SetActorLocation(SceneUtils.ServerPos2ClientPos(to_pos_list[currentIndex]))
    end
  end
  Log.PrintScreenMsg("ServerAIComponent:InitMove_BezierFly \230\129\162\229\164\141\231\167\187\229\138\168\239\188\129\239\188\129 %s", self.owner.config.name)
  self:ServerFly(bezier_fly_info)
end

function ServerAIComponent:InitMove_Jump(jump_info)
  if jump_info.start_pos and not self:OwnerResourceLoaded() then
    self:SetActorLocation(SceneUtils.ServerPos2ClientPos(jump_info.start_pos))
    Log.PrintScreenMsg("ServerAIComponent:InitMove_Jump %s", self.owner.config.name)
  end
  self:Launch(jump_info)
end

function ServerAIComponent:OwnerResourceLoaded()
  return self.owner.viewObj and self.owner.viewObj.resourceLoaded
end

return ServerAIComponent

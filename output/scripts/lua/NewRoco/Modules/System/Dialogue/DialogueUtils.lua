local SceneUtils = require("NewRoco.Modules.Core.Scene.Common.SceneUtils")
local LuaMathUtils = require("NewRoco.Utils.LuaMathUtils")
local DialogueConst = require("NewRoco.Modules.System.Dialogue.DialogueConst")
local BattleEnum = require("NewRoco.Modules.Core.Battle.Common.BattleEnum")
local DialogueModuleEvent = require("NewRoco.Modules.System.Dialogue.DialogueModuleEvent")
local DialogueUtils = {}
DialogueUtils.SkipDialogue = false
DialogueUtils.SkipTyping = false
DialogueUtils.HideDialogueBlack = false

function DialogueUtils.GetPlayer()
  local Player = _G.NRCModeManager:DoCmd(_G.PlayerModuleCmd.GET_LOCAL_PLAYER)
  return Player
end

function DialogueUtils.GetHero()
  local player = _G.NRCModuleManager:DoCmd(PlayerModuleCmd.GET_LOCAL_PLAYER)
  if player and player:IsInTogetherMove() and player:IsTogetherMove2P() then
    local other_player = player:GetAnotherTogetherMovePlayer()
    return other_player
  end
  return player
end

function DialogueUtils.FindNPC(id, npc_content_id)
  npc_content_id = npc_content_id or 0
  local npc = npc_content_id > 0 and _G.NRCModeManager:DoCmd(_G.NPCModuleCmd.GetNpcByRefreshID, npc_content_id) or nil
  if _G.RocoEnv.IS_EDITOR and npc and npc.config and npc.config.id ~= id then
    Log.WarningFormat("DialogueUtils.FindNPC: npc id %d \229\146\140 npc refresh content id %d\239\188\136\229\175\185\229\186\148npc id %d) \228\184\141\229\140\185\233\133\141!", id or 0, npc_content_id or 0, npc.config.id or 0)
  end
  npc = npc or _G.NRCModeManager:DoCmd(_G.NPCModuleCmd.FindNPCByConfigId, id)
  return npc
end

function DialogueUtils.GetPlayerView(Player)
  return Player and Player.viewObj
end

function DialogueUtils.GetController(Player)
  return Player and Player:GetUEController()
end

function DialogueUtils.GetPlayerSpringArm(Player)
  local Controller = DialogueUtils.GetController(Player)
  return Controller and Controller.BP_RocoCameraControlComponent and Controller.BP_RocoCameraControlComponent:GetSpringArmComponent()
end

function DialogueUtils.CallAndRemoveCallback(this, CallerName, CallbackName, ...)
  CallerName = CallerName or "autoCaller"
  CallbackName = CallbackName or "autoCallback"
  local caller = this[CallerName]
  local callback = this[CallbackName]
  if not callback then
    return false
  end
  callback(caller, ...)
  this[CallbackName] = nil
  this[CallerName] = nil
  return true
end

function DialogueUtils.RegisterCallback(this, Caller, Callback, CallerName, CallbackName)
  if not Caller or not Callback then
    Log.Warning("No valid Callback inputed, returning")
    return
  end
  CallerName = CallerName or "autoCaller"
  CallbackName = CallbackName or "autoCallback"
  if this[CallerName] or this[CallbackName] then
    Log.Error("Callback name conflict, this is not tolerated")
  end
  this[CallerName] = Caller
  this[CallbackName] = Callback
end

function DialogueUtils.StopTurn(actor)
  if not actor then
    return
  end
  local TurnComponent = actor.TurnComponent
  if TurnComponent then
    TurnComponent:StopTurn(AIDefines.ActionResult.Aborted, true)
  end
end

function DialogueUtils.StopLookAt(Actor)
  if not Actor then
    return
  end
  local LookAt = Actor:GetHeadLookAtComponent()
  if not LookAt then
    return
  end
  LookAt:ResetAutoLookAt()
end

function DialogueUtils.ClearLookAt(Actor)
  if not Actor then
    return
  end
  local LookAt = Actor:GetHeadLookAtComponent()
  if not LookAt then
    return
  end
  LookAt:EnableManualOverride()
  LookAt:ResetAutoLookAt()
end

function DialogueUtils.StopTalk(Actor, FadeOutTime)
  FadeOutTime = FadeOutTime or 0.1
  local View = DialogueUtils.ExtraActorView(Actor)
  local MeshComp = View and View.Mesh
  if not MeshComp then
    return
  end
  if not UE.UObject.IsValid(MeshComp) then
    return
  end
  if not MeshComp:IsA(UE.USkeletalMeshComponent) then
    return
  end
  local AnimInstance = MeshComp and MeshComp:GetAnimInstance()
  if not AnimInstance then
    return
  end
  if not UE.UObject.IsValid(AnimInstance) then
    return
  end
  if AnimInstance:IsA(UE.UCharacterEmotionAnimInstance) then
    AnimInstance:StopEmotion(FadeOutTime)
  end
end

function DialogueUtils.ToggleAI(actor, enabled, SendDialogueEndEvent)
  if not actor then
    return
  end
  local AIComponent = actor.AIComponent
  if AIComponent then
    AIComponent:ForceLockForReason(not enabled, true, AIDefines.LockReason.DIALOGUE)
    if enabled and SendDialogueEndEvent and AIComponent:IsActive() then
      local Controller = AIComponent.AIController
      if Controller and UE.UObject.IsValid(Controller) then
        Controller:NotifyDotsWorldEvent(Enum.DotsAIWorldEventType.DAWET_DIALOGUE_END)
      end
    end
  end
end

function DialogueUtils.ToggleInput(enabled)
  _G.UE4Helper.ToggleInput(DialogueUtils, enabled, "Dialogue")
end

function DialogueUtils.ToggleLOD(Actor, Enable)
  if not Actor then
    return
  end
  local Mesh = Actor.viewObj and Actor.viewObj.Mesh
  if not UE.UObject.IsValid(Mesh) then
    return
  end
  if not Mesh.SetForcedLOD then
    return
  end
  Mesh:SetForcedLOD(Enable and 1 or 0)
end

function DialogueUtils.ToggleSignificance(Actor, Enabled)
  if not Actor then
    return
  end
  if not Actor.SetSignificant then
    return
  end
  if Enabled then
    Actor:SetSignificant(false, UE.ESignificanceValue.Highest)
  else
    Actor:SetSignificant(true)
  end
end

function DialogueUtils.RestoreBornTransform(Actor)
  local View = Actor and Actor.viewObj
  if not View then
    return
  end
  local Pos = Actor.landPos
  local Rot = Actor.serverDataRotate
  if Pos and Rot then
    Actor:SetActorRotation(Rot)
    Actor:SetActorLocation(Pos)
  end
end

function DialogueUtils.GetBornTransform(NPC)
  local ServerData = NPC and NPC.serverData
  local BornPos = ServerData and ServerData.base.born_pt
  if not BornPos then
    return nil
  end
  local Transform = SceneUtils.ConvertPointToTransform(BornPos)
  return Transform
end

function DialogueUtils.PinOnGround(Actor, Transform)
  if not Actor then
    Log.Error("\230\151\160\230\179\149\232\142\183\229\143\150Actor\239\188\129\239\188\129")
    return
  end
  local View = Actor.viewObj
  if not View then
    return
  end
  local NewPosition = UE.UNRCStatics.GetPosInNearLand(View, Transform.Translation, Actor:GetHalfHeight())
  Transform.Translation = NewPosition
  View:Abs_K2_SetActorTransform_WithoutHit(Transform, false, false)
end

DialogueUtils.SettingsEnum = {A = 1, B = 2}

function DialogueUtils.PlayAnim(Actor, Action)
  if not Actor then
    return
  end
  if string.IsNilOrEmpty(Action) then
    return
  end
  local StartsWithPerform = string.StartsWith(Action, "perform:")
  if StartsWithPerform then
    local perform = string.sub(Action, 9)
    local performId = tonumber(perform)
    local performConf = _G.DataConfigManager:GetPerformConf(performId)
    Log.Debug("Do Perform ", perform)
    Actor:PlayShowById(performConf)
    return
  end
  local LinkTag = Actor.name == "SceneLocalPlayer" and "Locomotion" or nil
  local StartsWithLoop = string.StartsWith(Action, "loop:")
  if StartsWithLoop then
    local Anim = string.sub(Action, 6)
    Actor:PlayAnim(Anim, 1, 0, 0.1, 0.1, -1, 0, LinkTag)
  else
    Actor:PlayAnim(Action, 1, 0, 0.15, 0.15, 1, 0, LinkTag)
  end
  return StartsWithLoop
end

function DialogueUtils.StopAnim(Actor, BlendOutTime)
  if not Actor then
    return
  end
  Actor:StopAllMontage(BlendOutTime or 0.1)
end

function DialogueUtils.ResetLookAt(Actor, immediately)
end

function DialogueUtils.CalcLookAt(FromActor, ToPos)
end

function DialogueUtils.GetActor(actor, npc)
  if -1 == actor then
    return DialogueUtils.GetHero()
  elseif -2 == actor then
    return npc
  else
    return DialogueUtils.FindNPC(actor)
  end
end

function DialogueUtils.GrabActor(ActorID, Fsm, NPCContentID)
  if (not ActorID or 0 == ActorID) and (not NPCContentID or 0 == NPCContentID) then
    return nil
  end
  if ActorID and ActorID < 0 and NPCContentID and NPCContentID > 0 then
    Log.WarningFormat("DialogueUtils.GrabActor: ActorID is negative but NPCContentID is positive. NPCContentID will be discarded. ActorID: %d, NPCContentID: %d", ActorID, NPCContentID)
  end
  if Fsm then
    local Extras = Fsm:GetProperty("ExtraActors")
    if Extras then
      local FoundActor = Extras[ActorID]
      if FoundActor then
        return FoundActor
      end
    end
    if -2 == ActorID then
      local TargetNPC = Fsm:GetProperty("TargetNPC")
      return TargetNPC
    end
    if Fsm:GetProperty("bInBattle") then
      if ActorID <= -11 and ActorID >= -70 then
        local BattlePawn = DialogueUtils.SearchBattlePawn(ActorID)
        return BattlePawn
      else
        return nil
      end
    end
  end
  if -1 == ActorID then
    return DialogueUtils.GetHero()
  end
  if ActorID >= 0 then
    local Actor = DialogueUtils.FindNPC(ActorID, NPCContentID)
    return Actor
  end
  return nil
end

function DialogueUtils.ExtraActorView(Actor)
  if not Actor then
    return nil
  end
  local ActorName = Actor.name
  local bIsBattle = "BattlePet" == ActorName or "BattlePlayer" == ActorName
  if bIsBattle then
    if Actor.model and UE.UObject.IsValid(Actor.model) then
      return Actor.model
    else
      return nil
    end
  end
  local bIsScene = "SceneNpc" == ActorName or "SceneLocalPlayer" == ActorName or "ScenePlayer" == ActorName
  if bIsScene then
    if Actor.viewObj and UE.UObject.IsValid(Actor.viewObj) then
      return Actor.viewObj
    end
  else
    return nil
  end
  return nil
end

function DialogueUtils.GrabActorView(ActorID, Fsm, NPCContentID)
  if -5 == ActorID then
    local Player = DialogueUtils.GetPlayer()
    local Controller = DialogueUtils.GetController(Player)
    if not Controller then
      return nil, nil
    end
    local ViewTarget = Controller:GetViewTarget()
    return ViewTarget, nil
  end
  if -5 == ActorID then
    local Controller = UE4.UGameplayStatics.GetPlayerControllerFromID(_G.UE4Helper.GetCurrentWorld(), 0)
    if Controller then
      local ViewTarget = Controller:GetViewTarget()
      return ViewTarget, nil
    end
  end
  local Actor = DialogueUtils.GrabActor(ActorID, Fsm, NPCContentID)
  if not Actor then
    return nil, nil
  end
  local View = DialogueUtils.ExtraActorView(Actor)
  return View, Actor
end

function DialogueUtils.ActorToString(Actor)
  if not Actor then
    return "No Actor"
  end
  local ActorName = Actor.name
  local bIsBattle = "BattlePet" == ActorName or "BattlePlayer" == ActorName
  if bIsBattle then
    if Actor.model and UE.UObject.IsValid(Actor.model) then
      return string.format("%s: %s", ActorName, UE.UObject.GetName(Actor.model))
    else
      return ActorName
    end
  end
  if "SceneNpc" == ActorName and Actor.DebugNPCNameAndID then
    return Actor:DebugNPCNameAndID()
  end
  local bIsScene = "SceneNpc" == ActorName or "SceneLocalPlayer" == ActorName or "ScenePlayer" == ActorName
  if bIsScene then
    if Actor.viewObj and UE.UObject.IsValid(Actor.viewObj) then
      return string.format("%s: %s", ActorName, UE.UObject.GetName(Actor.viewObj))
    else
      return ActorName
    end
  end
  return ActorName
end

function DialogueUtils.GrabActorTransform(ActorID, Fsm, NPCContentID)
  local ActorTrans
  if -7 == ActorID then
    ActorTrans = SceneUtils.GetWorldOriginTransform()
    return ActorTrans
  end
  if -6 == ActorID and Fsm then
    local AbsoluteTransform = Fsm:GetProperty("BornTransform")
    AbsoluteTransform = AbsoluteTransform or UE.FTransform()
    local NewLoc = SceneUtils.ConvertAbsoluteToRelative(AbsoluteTransform.Translation)
    ActorTrans = UE.FTransform(AbsoluteTransform.Rotation, NewLoc, AbsoluteTransform.Scale3D)
    return ActorTrans
  end
  local View, TargetActor = DialogueUtils.GrabActorView(ActorID, Fsm, NPCContentID)
  if not View then
    Log.Error("\230\151\160\230\179\149\230\137\190\229\136\176\230\140\135\229\174\154\231\154\132\232\167\146\232\137\178view object is nil", ActorID)
    return nil, nil, nil
  end
  ActorTrans = View:GetTransform()
  return ActorTrans, View, TargetActor
end

function DialogueUtils.BuildBattleActors()
  local PawnManager = _G.BattleManager.battlePawnManager
  local PlayerTeams = PawnManager.AllPlayerTeam
  local EnemyTeams = PawnManager.AllEnemyTeam
  local PlayerTeam = PawnManager:GetTeam(BattleEnum.Team.ENUM_TEAM)
  local EnemyTeam = PawnManager:GetTeam(BattleEnum.Team.ENUM_ENEMY)
  local Actors = setmetatable({
    [-1] = PlayerTeam and PlayerTeam.player,
    [-2] = EnemyTeam and EnemyTeam.player
  }, {__mode = "kv"})
  if PlayerTeams then
    for _, Player in ipairs(PlayerTeams) do
      local ID = Player.player.roleInfo.base.npc_id
      Actors[ID] = Player
    end
  end
  if EnemyTeams then
    for _, Player in ipairs(EnemyTeams) do
      local ID = Player.player.roleInfo.base.npc_id
      Actors[ID] = Player
    end
  end
  return Actors
end

function DialogueUtils.SearchBattlePawn(ActorID)
  if ActorID > -11 then
    return nil
  end
  if ActorID < -61 then
    return nil
  end
  local PawnManager = _G.BattleManager.battlePawnManager
  if ActorID <= -11 and ActorID >= -20 then
    ActorID = -10 - ActorID
    local Teams = PawnManager.AllPlayerTeam
    local Team = Teams and Teams[ActorID]
    if Team then
      return Team.player
    end
  elseif ActorID <= -21 and ActorID >= -30 then
    ActorID = -20 - ActorID
    local TeamID = math.floor((ActorID - 1) / 3)
    ActorID = ActorID - TeamID * 3
    TeamID = TeamID + 1
    local Teams = PawnManager.AllPlayerTeam
    local Team = Teams and Teams[TeamID]
    local Pets = Team and Team.pets
    local Pet = Pets and Pets[ActorID]
    if Pet and Pet:GetCard():IsExistAtField() then
      return Pet
    end
  elseif ActorID <= -31 and ActorID >= -40 then
    ActorID = -30 - ActorID
    local Teams = PawnManager.AllEnemyTeam
    local Team = Teams and Teams[ActorID]
    if Team then
      return Team.player
    end
  elseif ActorID <= -41 and ActorID >= -50 then
    ActorID = -40 - ActorID
    local TeamID = math.floor((ActorID - 1) / 3)
    ActorID = ActorID - TeamID * 3
    TeamID = TeamID + 1
    local Teams = PawnManager.AllEnemyTeam
    local Team = Teams and Teams[TeamID]
    local Pets = Team and Team.pets
    local Pet = Pets and Pets[ActorID]
    if Pet and Pet:GetCard():IsExistAtField() then
      return Pet
    end
  elseif ActorID <= -51 and ActorID >= -60 then
    ActorID = -50 - ActorID
  elseif -61 == ActorID then
    return _G.BattleManager.battleRuntimeData:GetFBP1DialogPet()
  end
  return nil
end

function DialogueUtils.IsActorPlayer(actor)
  return -1 == actor
end

function DialogueUtils.CalcSpringArmOffsetFromPosition(aPos, bPos, aMesh)
  if not (aPos and bPos) or not aMesh then
    return nil
  end
  local OffsetFromA = (aPos - bPos) / 2
  if aMesh then
    local Radius = math.min(aMesh:GetImportedBounds().BoxExtent.X, aMesh:GetImportedBounds().BoxExtent.Y)
    local Dist = OffsetFromA:Size2D()
    if Radius > Dist or Radius > Dist then
      return UE4.FVector()
    else
      return OffsetFromA
    end
  else
    return OffsetFromA
  end
end

function DialogueUtils.CalcSpringArmOffset(a, b)
  if not a or not b then
    return nil
  end
  local aMesh = DialogueUtils.GetSkeletalMesh(a)
  local aPos = a:GetActorLocation()
  local bPos = b:GetActorLocation()
  return DialogueUtils.CalcSpringArmOffsetFromPosition(aPos, bPos, aMesh)
end

function DialogueUtils.CalcSpringArmOffsetSocket(a, b)
  local aPos, bPos
  local aMesh = DialogueUtils.GetSkeletalMesh(a)
  if aMesh then
    aPos = a:GetActorLocation() + UE4.FVector(0, 0, aMesh:GetImportedBounds().BoxExtent.Z)
  else
    aPos = a:GetActorLocation()
  end
  local bMesh = DialogueUtils.GetSkeletalMesh(b)
  if bMesh then
    bPos = b:GetActorLocation() + UE4.FVector(0, 0, bMesh:GetImportedBounds().BoxExtent.Z)
  else
    bPos = b:GetActorLocation()
  end
  local OffsetFromA = (aPos - bPos) / 2
  if aMesh then
    local Radius = math.min(aMesh:GetImportedBounds().BoxExtent.X, aMesh:GetImportedBounds().BoxExtent.Y)
    local Dist = OffsetFromA:Size2D()
    if Radius > Dist or Radius > Dist then
      return UE4.FVector()
    else
      return OffsetFromA
    end
  else
    return OffsetFromA
  end
end

function DialogueUtils.CalcSpringArmOffsetZ(a, b)
  if b:GetActorLocation().Z <= a:GetActorLocation().Z then
    return 0
  else
    return a:GetActorLocation().Z - b:GetActorLocation().Z
  end
end

function DialogueUtils.CalcSocketCenterLocation(a, b)
  local aPos, bPos
  local aMesh = DialogueUtils.GetSkeletalMesh(a)
  if aMesh then
    aPos = a:GetActorLocation() + UE4.FVector(0, 0, aMesh:GetImportedBounds().BoxExtent.Z)
  else
    aPos = a:GetActorLocation()
  end
  local bMesh = DialogueUtils.GetSkeletalMesh(b)
  if bMesh then
    bPos = b:GetActorLocation() + UE4.FVector(0, 0, bMesh:GetImportedBounds().BoxExtent.Z)
  else
    bPos = b:GetActorLocation()
  end
  local OffsetFromA = (aPos + bPos) / 2
  return OffsetFromA
end

function DialogueUtils.GetOverShoulderRotation(target, player, springArmLength, centerPos)
  local mesh = DialogueUtils.GetSkeletalMesh(player)
  local playerPos = player:GetActorLocation() + UE4.FVector(0, 0, mesh:GetImportedBounds().BoxExtent.Z)
  local dir = centerPos - playerPos
  local offsetZ = centerPos.z - playerPos.z
  local pitch = UE4.UKismetMathLibrary.DegAsin(offsetZ / springArmLength)
  local rot = dir:ToRotator()
  rot.Pitch = pitch
  rot.Yaw = rot.Yaw + DialogueConst.SpringArmYawBase
  return rot
end

function DialogueUtils.CalcActorDistance(a, b)
  if not a or not b then
    return nil
  end
  local aPos = a:GetActorLocation()
  local bPos = b:GetActorLocation()
  local distance = (aPos - bPos) / 2
  return distance:Size()
end

function DialogueUtils.CalcActorBpDistance(a, b)
  if not a or not b then
    return nil
  end
  local aPos = a:Abs_K2_GetActorLocation()
  local bPos = b:Abs_K2_GetActorLocation()
  local distance = (aPos - bPos) / 2
  return distance:Size()
end

function DialogueUtils.GetSkeletalMesh(a)
  local Comp = DialogueUtils.GetSkeletalMeshComp(a)
  if not Comp then
    return nil
  end
  return Comp.SkeletalMesh
end

function DialogueUtils.GetSkeletalMeshComp(a)
  if not a then
    return nil
  end
  local viewObj = DialogueUtils.ExtraActorView(a)
  if not viewObj then
    return nil
  end
  local Comp = viewObj:GetComponentByClass(UE4.USkeletalMeshComponent)
  return Comp
end

function DialogueUtils.GetDirection(a, b, ignoreZ)
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

function DialogueUtils.LookAt(a, b)
  if not a or not b then
    return
  end
  local Rot = DialogueUtils.GetDirection(a, b, true)
  if Rot then
    a:SetActorRotation(Rot)
  end
end

function DialogueUtils.ClampAngle(Angle)
  return (Angle + 360) % 360
end

function DialogueUtils.AdjustControlDirection(Control, Stand)
  Log.DebugFormat("V1:%s,V2:%s", tostring(Control), tostring(Stand))
  local YawDiff = 0
  Stand.Yaw, Control.Yaw, YawDiff = LuaMathUtils.DiffAngle(Stand.Yaw, Control.Yaw)
  if math.abs(YawDiff) <= DialogueConst.MiniYawDiff then
    if YawDiff < 0 then
      Control.Yaw = Stand.Yaw + DialogueConst.AdjustYawOffset
    else
      Control.Yaw = Stand.Yaw - DialogueConst.AdjustYawOffset
    end
  end
  if Control.Pitch > DialogueConst.PitchCheckThreshold and Control.Pitch < 90 then
    Control.Pitch = DialogueConst.AdjustPitchOffset
  end
  return Control
end

function DialogueUtils.AdjustControlDirectionByCollisionAndStep(Rot, Center, Length, Radius, Step, Channel)
  for i = 0, Step do
    if 0 == i then
      local ans, rotAns = DialogueUtils.AdjustControlDirectionByCollision(Rot, Center, Length, Radius, Step, Channel)
      if ans then
        return rotAns
      end
    else
      local rot1 = UE4.FRotator(Rot.Pitch, Rot.Yaw + i * 180 / Step, Rot.Roll)
      local ans1, rotAns1 = DialogueUtils.AdjustControlDirectionByCollision(rot1, Center, Length, Radius, Step, Channel)
      if ans1 then
        return rotAns1
      end
      local rot2 = UE4.FRotator(Rot.Pitch, Rot.Yaw - i * 180 / Step, Rot.Roll)
      local ans2, rotAns2 = DialogueUtils.AdjustControlDirectionByCollision(rot2, Center, Length, Radius, Step, Channel)
      if ans2 then
        return rotAns2
      end
    end
  end
  return Rot
end

function DialogueUtils.AdjustControlDirectionByCollision(Rot, Center, Length, Radius, Step, Channel)
  local rot = Rot
  local vec = rot:ToVector()
  local End = Center - vec * Length
  local World = _G.UE4Helper.GetCurrentWorld()
  local Hit, Sweep = DialogueUtils.Sweep(World, Channel, Radius, Center, End)
  if not Hit then
    return true, rot
  else
    local tmp = UE4.FVector(Sweep.X - Center.X, Sweep.Y - Center.Y, Sweep.Z - Center.Z)
    local hitLength = tmp:Size()
    if hitLength > Length * 0.9 then
      return true, rot
    end
  end
  return false
end

function DialogueUtils.Sweep(World, Channel, Radius, From, To)
  local Player = DialogueUtils.GetPlayer()
  local PlayerView = Player and Player.viewObj
  if not PlayerView then
    return
  end
  local Hit = UE4.FHitResult()
  UE4.UKismetSystemLibrary.SphereTraceSingle(World, From, To, Radius, Channel, false, {PlayerView}, 0, Hit, true)
  if Hit.bBlockingHit then
    return true, Hit.Location
  else
    return false, To
  end
end

function DialogueUtils.GetSelectInfoByID(Action, id)
  if not Action then
    return nil
  end
  local Infos = Action.select_infos
  if not Infos then
    return nil
  end
  if 0 == #Infos then
    return nil
  end
  for _, Info in ipairs(Infos) do
    if Info.select_id == id then
      return Info
    end
  end
  return nil
end

function DialogueUtils.HasValidAction(conf)
  if not conf then
    return false
  end
  local Action = conf.action
  if not Action then
    return false
  end
  if Action and Action.action_type then
    return Action.action_type ~= Enum.ActionType.ACT_NONE
  else
    return false
  end
end

function DialogueUtils.ChangeCamera(Camera, DeltaTime, BlendFunc, controller, Callback, Caller)
  DeltaTime = DeltaTime or 0
  BlendFunc = BlendFunc or UE4.EViewTargetBlendFunction.VTBlend_EaseOut
  controller:SetViewTargetWithBlend(Camera, DeltaTime, BlendFunc, 2)
  if Callback then
    _G.DelayManager:DelaySeconds(DeltaTime, Callback, Caller)
  end
end

function DialogueUtils.SetPlayerVisible(player, isVisible)
  if not player then
    return
  end
  player:SetVisible(isVisible)
end

function DialogueUtils.GetDialogueModule()
  return NRCModuleManager:GetModule("DialogueModule")
end

function DialogueUtils.CheckEndDialogStatus()
  if not DialogueUtils.GetDialogueModule() then
    DialogueUtils.SetEndDialogCamera()
    return true
  else
    local HasDialogue = _G.DialogueModuleCmd and _G.NRCModuleManager:DoCmd(_G.DialogueModuleCmd.HasDialogue)
    if not HasDialogue then
      DialogueUtils.SetEndDialogCamera()
      return true
    end
    return false
  end
end

function DialogueUtils.SetEndDialogCamera()
  local Player = DialogueUtils.GetPlayer()
  if not Player then
    return
  end
  local SpringArm = DialogueUtils.GetPlayerSpringArm(Player)
  if not SpringArm then
    return
  end
  SpringArm.ProbeChannel = UE4.ECollisionChannel.ECC_Camera
end

function DialogueUtils.GetActorMesh(actor)
  local meshComponent
  if actor then
    meshComponent = actor:GetComponentByClass(UE4.USkeletalMeshComponent)
    if not meshComponent or not meshComponent.SkeletalMesh then
      meshComponent = actor:GetComponentByClass(UE4.UStaticMeshComponent)
    end
    meshComponent = meshComponent or actor:GetComponentByClass(UE4.UInstancedStaticMeshComponent)
  end
  return meshComponent
end

function DialogueUtils.IsValidToShow(x, y, z)
  if x * y * z >= DialogueConst.HideObjectParam.MaxHideVolume or x * y * z <= DialogueConst.HideObjectParam.MinHideVolume or x <= DialogueConst.HideObjectParam.SingleMeshMinX or y <= DialogueConst.HideObjectParam.SingleMeshMinY or z <= DialogueConst.HideObjectParam.SingleMeshMinZ then
    return true
  else
    return false
  end
end

function DialogueUtils.SetDialogObjectIgnoreCollision(Center, ignoreAll)
  local World = _G.UE4Helper.GetCurrentWorld()
  local outActors, result = UE4.UKismetSystemLibrary.Abs_SphereOverlapActors(World, Center, DialogueConst.HideObjectParam.CheckRadius, nil, nil, nil, nil)
  if result then
    for i = 1, outActors:Length() do
      local curActor = outActors:Get(i)
      if not curActor:IsA(UE4.AInstancedFoliageActor) then
        local nameCheck = false
        if curActor:GetName() then
          local foundIdx = string.find(curActor:GetName(), "\233\173\148\229\138\155\228\185\139\230\186\144")
          if foundIdx and foundIdx >= 0 then
            DialogueUtils.SetActorMeshDialogCollision(curActor)
            nameCheck = true
          end
        end
        if not nameCheck then
          local Origin, Extend = curActor:GetActorBounds()
          if not DialogueUtils.IsValidToShow(Extend.x, Extend.y, Extend.z) then
          end
        end
      elseif ignoreAll then
      end
    end
  else
    Log.Debug("not blocking")
  end
end

function DialogueUtils.SetActorMeshDialogCollision(actor)
  local skeletalMeshComps = actor:K2_GetComponentsByClass(UE4.USkeletalMeshComponent)
  DialogueUtils.SetCompsDialogCollision(skeletalMeshComps)
  local staticMeshComps = actor:K2_GetComponentsByClass(UE4.UStaticMeshComponent)
  DialogueUtils.SetCompsDialogCollision(staticMeshComps)
  local instancedStaticMeshComps = actor:K2_GetComponentsByClass(UE4.UInstancedStaticMeshComponent)
  DialogueUtils.SetCompsDialogCollision(instancedStaticMeshComps)
end

function DialogueUtils.SetCompsDialogCollision(comps)
  for idx = 1, comps:Length() do
    local comp = comps:Get(idx)
    if comp then
      comp:SetCollisionProfileName("Custom")
      comp:SetGenerateOverlapEvents(false)
      comp:SetCollisionResponseToChannel(UE4.ECollisionChannel.DialogCamera, UE4.ECollisionResponse.ECR_Ignore)
    end
  end
end

function DialogueUtils.ResolveDialogueID(Action)
  if not Action then
    return 0
  end
  local CurrentDialogueID = Action.dialog_id
  if 0 == CurrentDialogueID then
    CurrentDialogueID = Action.bound_dialog_id
  end
  if Action.act_status == ProtoEnum.SpaceEnum_NpcActionStatus.ENUM.Executing then
    return CurrentDialogueID
  end
  if Action.act_status ~= ProtoEnum.SpaceEnum_NpcActionStatus.ENUM.Commited then
    return CurrentDialogueID
  end
  return Action.next_dialog_id
end

function DialogueUtils.CheckDialogueContainActions(DialogueID, Actions)
  local DialogueMap = {}
  DialogueUtils.CollectDialogues(DialogueID, DialogueMap)
  return DialogueUtils.ContainsAction(DialogueMap, Actions)
end

function DialogueUtils.ContainsAction(Collected, Actions)
  if not Collected then
    return false
  end
  if not Actions then
    return false
  end
  for ID, Conf in pairs(Collected) do
    local Type = Conf.action.action_type
    if Type and Type > 0 and table.contains(Actions, Type) then
      Log.Debug("\229\175\185\232\175\157", ID, "\229\140\133\229\144\171\228\186\134\230\140\135\229\174\154\231\154\132Action")
      return true
    end
  end
  return false
end

function DialogueUtils.CollectDialogues(DialogueID, Collected)
  if not DialogueID then
    return
  end
  if 0 == DialogueID then
    return
  end
  if not Collected then
    return
  end
  
  local function SimpleCollector(Conf, CollectedDialogues)
    if CollectedDialogues[Conf.id] then
      CollectedDialogues[Conf.id] = Conf
    end
  end
  
  DialogueUtils.WalkDialogues(DialogueID, nil, SimpleCollector, Collected)
end

function DialogueUtils.WalkDialogues(DialogueID, Walker, WalkFunc, ...)
  local Visited = {}
  DialogueUtils.InternalWalkDialogues(DialogueID, Visited, Walker, WalkFunc, ...)
  return Visited
end

function DialogueUtils.InternalWalkDialogues(DialogueID, Visited, Walker, WalkFunc, ...)
  if not DialogueID then
    return
  end
  if 0 == DialogueID then
    return
  end
  if not WalkFunc then
    return
  end
  if table.contains(Visited, DialogueID) then
    return
  end
  table.insert(Visited, DialogueID)
  local Conf = _G.DataConfigManager:GetDialogueConf(DialogueID)
  if not Conf then
    return
  end
  if Walker then
    WalkFunc(Walker, Conf, ...)
  else
    WalkFunc(Conf, ...)
  end
  local ActionType = Conf.action.action_type
  if 0 ~= Conf.next_dialog_id then
    DialogueUtils.InternalWalkDialogues(Conf.next_dialog_id, Visited, Walker, WalkFunc, ...)
  elseif Conf.select_ids and #Conf.select_ids > 0 then
    for _, SelectID in ipairs(Conf.select_ids) do
      local SelectConf = _G.DataConfigManager:GetSelectConf(SelectID)
      if SelectConf then
        DialogueUtils.InternalWalkDialogues(SelectConf.select_next_dialogue, Visited, Walker, WalkFunc, ...)
        DialogueUtils.InternalWalkDialogues(SelectConf.notimes_dialogue, Visited, Walker, WalkFunc, ...)
      end
    end
  elseif ActionType and 0 ~= ActionType then
    DialogueUtils.InternalWalkDialogues(Conf.action.success_dialogue, Visited, Walker, WalkFunc, ...)
    DialogueUtils.InternalWalkDialogues(Conf.action.failure_dialogue, Visited, Walker, WalkFunc, ...)
    local ActionResultConf = _G.DataConfigManager:GetActionResultTypeConf(DialogueID, true)
    if ActionResultConf and ActionResultConf.expand_dialogs then
      for _, Expand in ipairs(ActionResultConf.expand_dialogs) do
        DialogueUtils.InternalWalkDialogues(Expand.expand_dialog_id, Visited, Walker, WalkFunc, ...)
      end
    end
  end
end

function DialogueUtils.HasBattle(ID)
  if not ID then
    return false
  end
  if 0 == ID then
    return false
  end
  local Conf = _G.DataConfigManager:GetDialogueConf(ID)
  if not Conf then
    return false
  end
  local ActionType = Conf.action.action_type
  if ActionType == Enum.ActionType.ACT_BATTLE then
    return true
  elseif ActionType == Enum.ActionType.ACT_TOUCHBATTLE then
    return true
  elseif ActionType == Enum.ActionType.ACT_ITEM_GET_RELY_BATTLE then
    return true
  end
  return false
end

function DialogueUtils.IsClientCommit(ActionType)
  ActionType = ActionType or 0
  local Conf = _G.DataConfigManager:GetNpcActionConf(ActionType, true)
  if Conf then
    return Conf.client_submit
  end
  return false
end

function DialogueUtils.IsTeleportAction(ActionType)
  return ActionType == Enum.ActionType.ACT_TELEPORT or ActionType == Enum.ActionType.ACT_ROLE_TELEPORT or ActionType == Enum.ActionType.ACT_SHORT_DISTANCE_TELEPORT
end

function DialogueUtils.LockPlayerMove()
  local localPlayer = _G.NRCModeManager:DoCmd(_G.PlayerModuleCmd.GET_LOCAL_PLAYER)
  local CharacterMovement = localPlayer.viewObj.CharacterMovement
  CharacterMovement:SetMovementMode(UE.EMovementMode.MOVE_Walking)
  CharacterMovement:SetActive(false)
  localPlayer:SetCharacterMovementTickEnable(DialogueUtils, false)
  localPlayer.viewObj:SetActorEnableCollision(false)
end

function DialogueUtils.UnlockPlayerMove()
  local localPlayer = _G.NRCModeManager:DoCmd(_G.PlayerModuleCmd.GET_LOCAL_PLAYER)
  localPlayer.viewObj:SetActorEnableCollision(true)
  local CharacterMovement = localPlayer.viewObj.CharacterMovement
  CharacterMovement:SetMovementMode(UE.EMovementMode.MOVE_Walking)
  CharacterMovement:SetActive(true)
  localPlayer:SetCharacterMovementTickEnable(DialogueUtils, true)
end

function DialogueUtils.CollectParticipants(DialogueID)
  local WalkPayload = {
    AutoTurn = true,
    Participants = {}
  }
  
  local function GrabTurnPerformer(Conf, Payload)
    if Payload.AutoTurn then
      for _, Perform in ipairs(Conf.actor_perform) do
        local Turn1 = Perform.turn_to or 0
        local Turn2 = Perform.body_turn_to or 0
        local Turn3 = Perform.eye_turn_to or 0
        if 0 ~= math.abs(Turn1) + math.abs(Turn2) + math.abs(Turn3) then
          Payload.AutoTurn = false
        end
      end
    end
    local Participants = Payload.Participants
    local SpeakerID = Conf.speaker or 0
    if SpeakerID > 0 and nil == Participants[SpeakerID] then
      local NPC = DialogueUtils.FindNPC(SpeakerID)
      if NPC then
        Participants[SpeakerID] = NPC
        DialogueUtils.ToggleLOD(NPC, true)
      else
        Participants[SpeakerID] = false
      end
    end
  end
  
  DialogueUtils.WalkDialogues(DialogueID, nil, GrabTurnPerformer, WalkPayload)
  if WalkPayload.AutoTurn then
    return WalkPayload.Participants
  else
    return nil
  end
end

function DialogueUtils.GetCameraTarget(Conf)
  if not Conf then
    return 0
  end
  local TargetNum = -2
  local P1 = tonumber(Conf.interact_camera_param1)
  local P4 = tonumber(Conf.interact_camera_param4) or -2
  if Conf.interact_camera_type == Enum.NpcInteractCameraType.NIC_1 then
    if -3 == P1 then
      TargetNum = P4
    elseif -4 == P1 then
      TargetNum = -2
    else
      TargetNum = P1
    end
  elseif Conf.interact_camera_type == Enum.NpcInteractCameraType.NIC_2 then
    if -3 == P1 then
      TargetNum = P4
    elseif -4 == P1 then
      TargetNum = -2
    else
      TargetNum = P1
    end
  elseif Conf.interact_camera_type == Enum.NpcInteractCameraType.NIC_3 then
    if -3 == P1 then
      TargetNum = P4
    else
      TargetNum = -2
    end
  elseif Conf.interact_camera_type == Enum.NpcInteractCameraType.NIC_4 then
    TargetNum = Conf.interact_camera_param2
  else
    TargetNum = -2
  end
  return TargetNum
end

function DialogueUtils.RecordPreActionTransform(Actor)
  if not Actor then
    return
  end
  local View = DialogueUtils.ExtraActorView(Actor)
  if not View then
    return
  end
  Actor.PreActionTransform = View:GetTransform()
end

function DialogueUtils.RestorePreActionTransform(Actor)
  if not Actor then
    return
  end
  local View = DialogueUtils.ExtraActorView(Actor)
  if not View then
    return
  end
  if not Actor.PreActionTransform then
    return
  end
  View:K2_SetActorTransform(Actor.PreActionTransform, false, nil, true)
end

function DialogueUtils.LogAction(Action, Content)
  Log.Debug(Content or "", Action.bound_dialog_id, Action.dialog_id, table.getKeyName(Enum.ActionType, Action.act_type), table.getKeyName(ProtoEnum.SpaceEnum_NpcActionStatus.ENUM, Action.act_status), DialogueUtils.IsClientCommit(Action.act_type) and "\229\174\162\230\136\183\231\171\175\230\143\144\228\186\164" or "\229\144\142\229\143\176\230\143\144\228\186\164")
end

function DialogueUtils.ToggleMovement(Actor, bEnable)
  if not Actor then
    return
  end
  local AIComp = Actor.AIComponent
  if AIComp and AIComp.isControllerCreated then
    return
  end
  local View = DialogueUtils.ExtraActorView(Actor)
  if not View then
    return
  end
  if View.Mesh then
    View.Mesh:SetEnableGravity(not bEnable)
  end
  local CharacterMovement = View and View.CharacterMovement
  if CharacterMovement and UE.UObject.IsValid(CharacterMovement) then
    if bEnable then
      CharacterMovement:SetMovementMode(UE4.EMovementMode.MOVE_Walking)
    else
      CharacterMovement.OnDirectGoalMoveFinish:Unbind()
      CharacterMovement:FinishDirectGoalMove(false)
      CharacterMovement.Velocity = UE4Helper.ZeroVector
      CharacterMovement:DisableMovement()
    end
  end
  if View.SetIKEnable then
    View:SetIKEnable(bEnable)
  end
  if View.EnableCanStandOnWaterSurface then
    View:EnableCanStandOnWaterSurface(not bEnable)
  end
  Log.Debug("DialogueUtils.ToggleMovement", UE.UObject.GetName(View), bEnable)
end

function DialogueUtils.ParseActorLocation(String, Actor)
  if nil == String then
    return
  end
  local Location = UE4.FVector(String.X, String.Y, String.Z)
  local View = DialogueUtils.ExtraActorView(Actor)
  if String.Base and String.Base == "Mesh" and View and View.Mesh then
    local meshToActorRelative = View.Mesh:GetRelativeTransform()
    Location = Location - meshToActorRelative.Translation
  end
  return Location
end

function DialogueUtils.ParseActorRotation(String, Actor)
  if nil == String then
    return
  end
  local Rotation = UE4.FRotator(String.Pitch, String.Yaw, String.Roll)
  return Rotation
end

function DialogueUtils.ToggleHideDialogueBlack()
  DialogueUtils.HideDialogueBlack = not DialogueUtils.HideDialogueBlack
  _G.NRCEventCenter:DispatchEvent(DialogueModuleEvent.OnHideDialogueBlackChange, DialogueUtils.HideDialogueBlack)
  Log.ErrorFormat("DialogueUtils.ToggleHideDialogueBlack to %s", DialogueUtils.HideDialogueBlack and "True" or "False")
end

function DialogueUtils.IsEntryDialogue(DialogueFSM)
  if not DialogueFSM then
    return false
  end
  local CurrentOption = DialogueFSM:GetProperty("CurrentOption")
  local OptionConf = CurrentOption and CurrentOption.config
  OptionConf = OptionConf or DialogueFSM:GetProperty("OptionConf")
  if not OptionConf then
    return false
  end
  if OptionConf.action.action_type ~= Enum.ActionType.ACT_DIALOG then
    return false
  end
  local CurConf = DialogueFSM:GetProperty("CurrentDialogue")
  if not CurConf then
    return false
  end
  local CurConfID = CurConf.id
  local LastConfID = DialogueFSM:GetProperty("LastConfID", 0)
  return tonumber(OptionConf.action.action_param1) == CurConfID and 0 == LastConfID
end

function DialogueUtils.SetAudioGender(InPlayer)
  local isMale = not InPlayer or not InPlayer.serverData or not InPlayer.serverData.base or 1 == InPlayer.serverData.base.gender
  if isMale then
    _G.NRCAudioManager:SetGlobalSwitch("Player_Gender", "Male")
  else
    _G.NRCAudioManager:SetGlobalSwitch("Player_Gender", "Female")
  end
end

return DialogueUtils

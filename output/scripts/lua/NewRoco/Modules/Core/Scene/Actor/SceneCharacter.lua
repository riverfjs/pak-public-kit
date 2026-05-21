local NPCModuleEvent = require("NewRoco.Modules.Core.NPC.NPCModuleEvent")
local TurnComponent = require("NewRoco.Modules.Core.Scene.Component.Movement.TurnComponent")
local LogicStatusComponent = require("NewRoco.Modules.Core.Scene.Component.Status.LogicStatusComponent")
local HoldingItemComponent = require("NewRoco.Modules.Core.Scene.Component.Show.HoldingItemComponent")
local SkillShowComponent = require("NewRoco.Modules.Core.Scene.Component.Show.SkillShowComponent")
local WorldCombatBuffComponent = require("NewRoco.Modules.Core.Scene.Component.WorldCombat.WorldCombatBuffComponent")
local Base = require("NewRoco.Modules.Core.Scene.Actor.SceneActor")
local SceneCharacter = Base:Extend("SceneCharacter")
SceneCharacter:SetMemberCount(16)

function SceneCharacter:PreCtor(module)
  Base.PreCtor(self, module)
  self.PlayerPosCache = UE.FVector()
  self.squaredDis2Local = 200000000
  self.squaredDis2LocalIgnoreZ = 200000000
  self.fowardDotValue = 1
  self.playerForwardDotValue = 1
  self.BuffSpeedScale = 1
  self.PlayerHeightDiff = 0
end

function SceneCharacter:DoHeadMotion(MotionType)
  if not self.viewObj then
    Log.Error("No view")
    return
  end
  if MotionType == Enum.HeadMotion.Nod and self.viewObj.Event_Action_Yes then
    self.viewObj:Event_Action_Yes()
  elseif MotionType == Enum.HeadMotion.Shake and self.viewObj.Event_Action_No then
    self.viewObj:Event_Action_No()
  elseif MotionType == Enum.HeadMotion.Lookup and self.viewObj.Event_Action_Lookup then
    self.viewObj:Event_Action_Lookup()
  end
end

function SceneCharacter:InitData(config, serverData)
  self.config = config
  self.serverData = serverData
  local serverDataRotate_z = 0
  local serverDataRotate_x = 0
  local serverDataRotate_y = 0
  if self.serverData.base.pt.dir.x then
    serverDataRotate_x = self.serverData.base.pt.dir.x / 10
  end
  if self.serverData.base.pt.dir.y then
    serverDataRotate_y = self.serverData.base.pt.dir.y / 10
  end
  if self.serverData.base.pt.dir.z then
    serverDataRotate_z = self.serverData.base.pt.dir.z / 10
  end
  self.serverDataRotate = UE4.FRotator(serverDataRotate_y, serverDataRotate_z, serverDataRotate_x)
end

function SceneCharacter:IsMagicReplayActor()
  if self.serverData then
    return self.serverData.is_magic_replay or false
  end
  return false
end

function SceneCharacter:IsServerStatus(logicStatus)
  if not self.serverData or not self.serverData.status_info then
    return nil
  end
  for _, Status in ipairs(self.serverData.status_info) do
    if Status.status == logicStatus then
      return true
    end
  end
  return false
end

function SceneCharacter:IsLogicStatus(logicStatus)
  return self:EnsureComponent(LogicStatusComponent):GetStatus(logicStatus)
end

function SceneCharacter:InitComponent()
  self:EnsureComponent(TurnComponent)
  self:EnsureComponent(LogicStatusComponent)
  if self.serverData and self.serverData.buff_info then
    self:EnsureComponent(WorldCombatBuffComponent)
  end
end

function SceneCharacter:SetViewObj(viewObj)
  Base.SetViewObj(self, viewObj)
  if UE.UObject.IsValid(self.viewObj) then
    self.viewObj.sceneCharacter = self
  end
end

function SceneCharacter:UpdateData(ServerData, isReconnect)
  self.serverData = ServerData
  if not self.components then
    return
  end
  local items = self.components:Items()
  for _, v in ipairs(items) do
    v:UpdateData(ServerData, isReconnect)
  end
end

function SceneCharacter:UpdateLogicStatus(action)
  local Comp = self:EnsureComponent(LogicStatusComponent)
  Comp:UpdateWithAction(action)
end

function SceneCharacter:UpdateLevel(newLevel)
end

function SceneCharacter:InitActor(url, pos, rotation)
  local characterClass = UE4.UNRCStatics.ResolveObject(url)
  if nil == characterClass then
    Log.Error("SceneCharacter:InitActor: npc/player\230\168\161\229\158\139\229\138\160\232\189\189\229\164\177\232\180\165\239\188\140\232\175\183\230\163\128\230\159\165\232\181\132\230\186\144\233\133\141\231\189\174 ", url)
    return false
  end
  local params = {}
  params.sceneCharacter = self
  local quat = UE4.FQuat.FromAxisAndAngle(UE4Helper.UpVector, rotation)
  local fTransfom = UE4.FTransform(quat, pos)
  local viewObj = _G.UE4Helper.GetCurrentWorld():Abs_SpawnActor(characterClass, fTransfom, UE4.ESpawnActorCollisionHandlingMethod.AdjustIfPossibleButAlwaysSpawn, nil, nil, nil, params)
  local serverRot = UE4.FRotator(0, rotation, 0)
  viewObj:K2_SetActorRotation(serverRot, true)
  self:SetViewObj(viewObj)
  if viewObj.OnInit then
    viewObj:OnInit()
  end
  self:CalSquaredDis2Local()
  if self:IsMagicReplayActor() then
    viewObj:SetHiddenMask(true, UE4.EPlayerForceHiddenType.MagicReplay)
  end
  return true
end

function SceneCharacter:CalSquaredDis2Local()
  local PlayerX, PlayerY, PlayerZ
  PlayerX, PlayerY, PlayerZ, self.squaredDis2Local, self.squaredDis2LocalIgnoreZ, self.fowardDotValue = UE.NPCUtils.CalcDist(self.viewObj, nil, nil)
  self.PlayerPosCache.X = PlayerX
  self.PlayerPosCache.Y = PlayerY
  self.PlayerPosCache.Z = PlayerZ
  self.PlayerHeightDiff = math.abs(PlayerZ - self:GetActorLocation().Z)
  return self.squaredDis2Local, self.squaredDis2LocalIgnoreZ
end

function SceneCharacter:GetUEController()
  if UE.UObject.IsValid(self.viewObj) then
    return self.viewObj.Controller
  end
end

function SceneCharacter:GetHalfHeight()
  if UE.UObject.IsValid(self.viewObj) and self.viewObj.GetHalfHeight then
    return self.viewObj:GetHalfHeight()
  end
  return 0
end

function SceneCharacter:GetScaledHalfHeight()
  local HalfHeight = self:GetHalfHeight()
  local Scale = self:GetActorScale3D()
  return HalfHeight * Scale.Z
end

function SceneCharacter:GetMeshScaledHalfHeight()
  local HalfHeight = self:GetHalfHeight()
  local scaleZ = 1
  if UE.UObject.IsValid(self.viewObj) then
    local CheckMesh = self.viewObj:GetComponentByClass(UE4.USkeletalMeshComponent)
    if CheckMesh then
      scaleZ = CheckMesh:K2_GetComponentScale().Z
    end
  end
  return HalfHeight * scaleZ
end

function SceneCharacter:GetRadius()
  if UE.UObject.IsValid(self.viewObj) and self.viewObj.GetRadius then
    return self.viewObj:GetRadius()
  end
  return 0
end

function SceneCharacter:GetScaledRadius()
  local Radius = self:GetRadius()
  local Scale = self:GetActorScale3D()
  return Radius * math.max(Scale.X, Scale.Y)
end

function SceneCharacter:OnBeginOverlap(other)
end

function SceneCharacter:OnEndOverlap(other)
end

function SceneCharacter:OnTouch()
end

function SceneCharacter:Stop()
  if UE.UObject.IsValid(self.viewObj) then
    if self.viewObj.StopWalkAndClimb and type(self.model.StopWalkAndClimb) == "function" then
      self.viewObj:StopWalkAndClimb()
    end
    if self.viewObj.CharacterMovement then
      self.viewObj.CharacterMovement:ConsumeInputVector()
      self.viewObj.CharacterMovement:ConsumeInputVector()
      self.viewObj.CharacterMovement:StopMovementImmediately()
      if self.isLocal then
        if self.movementComponent then
          self.movementComponent:ClearMoveInput()
        end
        if self.statusComponent and self.viewObj.BP_RideComponent then
          local RidePet = self.viewObj.BP_RideComponent.RidePet
          if RidePet then
            self.statusComponent:RemoveStatus(ProtoEnum.WorldPlayerStatusType.WPST_RIDEALL_ABILITY)
            local RideMovement = RidePet.CharacterMovement
            RideMovement:ConsumeInputVector()
            RideMovement:ConsumeInputVector()
            RideMovement:StopMovementImmediately()
          end
        end
      end
      if self.viewObj.CharacterMovement.bIsMantle then
        self.viewObj.CharacterMovement:MantleEnd()
      end
    end
    if self.viewObj.Stop then
      self.viewObj:Stop()
    end
  end
end

function SceneCharacter:FaceTo(sceneCharacter)
  if sceneCharacter then
    local dir = sceneCharacter:GetActorLocation() - self:GetActorLocation()
    dir.Z = 0
    self:SetActorRotation(dir:ToRotator())
  end
end

function SceneCharacter:GetActorTransform()
  if UE.UObject.IsValid(self.viewObj) then
    return self.viewObj:Abs_GetTransform()
  end
  return UE4.FTransform()
end

local IdentityTransform = UE4.FTransform()

function SceneCharacter:GetActorTransformInplace(transform, translation, rotation, scale)
  if UE.UObject.IsValid(self.viewObj) then
    UE4.UNRCStatics.Abs_GetActorTransformInplace(self.viewObj, transform, translation, rotation, scale)
    return
  end
  transform:CopyFrom(IdentityTransform)
  translation:Set(0, 0, 0)
  rotation:Set(0, 0, 0, 1)
  scale:Set(1, 1, 1)
end

function SceneCharacter:GetActorLocationInplace(location)
  if UE.UObject.IsValid(self.viewObj) then
    UE4.UNRCStatics.Abs_K2_GetActorLocationInplace(self.viewObj, location)
    return
  end
  location:Set(0, 0, 0)
end

function SceneCharacter:GetActorRotationInplace(rotation)
  if UE.UObject.IsValid(self.viewObj) then
    UE4.UNRCStatics.K2_GetActorRotationInplace(self.viewObj, rotation)
    return
  end
  rotation:Set(0, 0, 0)
end

function SceneCharacter:GetActorLocation()
  if UE.UObject.IsValid(self.viewObj) then
    return self.viewObj:Abs_K2_GetActorLocation()
  end
  return UE4.FVector(0, 0, 0)
end

function SceneCharacter:GetActorRotation()
  if UE.UObject.IsValid(self.viewObj) then
    return self.viewObj:K2_GetActorRotation()
  end
  return UE4.FRotator(0, 0, 0)
end

function SceneCharacter:GetActorScale3D()
  if UE.UObject.IsValid(self.viewObj) then
    return self.viewObj:GetActorScale3D()
  end
  return UE4.FVector(1, 1, 1)
end

function SceneCharacter:SetActorLocation(pos)
  if UE.UObject.IsValid(self.viewObj) then
    self.viewObj:Abs_K2_SetActorLocation_WithoutHit(pos, false, true)
  end
end

function SceneCharacter:SetActorRotation(rotate)
  local Model = self.viewObj
  if UE.UObject.IsValid(Model) then
    if Model.Event_StopTurn then
      Model:Event_StopTurn()
    end
    if Model.ClearTargetRotator then
      Model:ClearTargetRotator()
    end
    Model:K2_SetActorRotation(rotate, true)
  end
end

function SceneCharacter:SetActorScale3D(scale)
  if UE.UObject.IsValid(self.viewObj) then
    self.viewObj:SetActorScale3D(scale)
  end
end

function SceneCharacter:IsMoving()
  if UE.UObject.IsValid(self.viewObj) and self.viewObj.IsMoving then
    return self.viewObj:IsMoving()
  end
  return false
end

function SceneCharacter:GetForwardVector()
  if UE.UObject.IsValid(self.viewObj) then
    return self.viewObj:GetActorForwardVector()
  end
  return UE4.FVector(1, 0, 0)
end

function SceneCharacter:GetRightVector()
  if UE.UObject.IsValid(self.viewObj) then
    return self.viewObj:GetActorRightVector()
  end
  return UE4.FVector(0, 1, 0)
end

function SceneCharacter:GetUpVector()
  if UE.UObject.IsValid(self.viewObj) then
    return self.viewObj:GetActorUpVector()
  end
  return UE4.FVector(0, 0, 1)
end

function SceneCharacter:IsNearBy(location, squaredDis)
  local pos = self:GetActorLocation()
  return squaredDis > UE4.FVector.DistSquared2D(pos, location)
end

function SceneCharacter:GetServerId()
  if self.serverData and self.serverData.brief_info and self.serverData.brief_info.uin then
    return self.serverData.brief_info.uin
  end
  return 0
end

function SceneCharacter:GetOwnerId()
  if self.serverData and self.serverData.base and self.serverData.base.owner_id then
    return self.serverData.base.owner_id
  end
  return self.owner_id or 0
end

function SceneCharacter:SetVisible(Visible)
  if UE.UObject.IsValid(self.viewObj) then
    self.viewObj:SetActorHiddenInGame(not Visible)
  end
end

function SceneCharacter:OnDestroyedByEngine()
  self.viewObj = nil
  self.viewObjRef = nil
end

function SceneCharacter:Destroy()
  Base.Destroy(self)
  self:DestroyModel()
  self.BuffSpeedScale = 1
end

function SceneCharacter:DestroyModel()
  if UE.UObject.IsValid(self.viewObj) then
    self.viewObj.sceneCharacter = nil
    if self.viewObj.K2_DestroyActor then
      self.viewObj:K2_DestroyActor()
    else
      Log.Error("SceneCharacter:DestroyModel, Actor no K2_DestroyActor ??")
    end
    self.viewObj = nil
    self.viewObjRef = nil
  end
end

function SceneCharacter:GetAnimComponent()
  if not self.viewObj or not UE.UObject.IsValid(self.viewObj) then
    return
  end
  if not self.viewObj.GetAnimComponent then
    return
  end
  local AnimComp = self.viewObj:GetAnimComponent()
  if AnimComp then
    return AnimComp
  end
  AnimComp = self.viewObj:GetComponentByClass(UE4.URocoAnimComponent)
  return AnimComp
end

function SceneCharacter:PlayAnim(Name, Rate, Position, BlendInTime, BlendOutTime, LoopCount, EndPosition, LinkedTag, bStopAllMontages, SlotName)
  local AnimComp = self:GetAnimComponent()
  if AnimComp then
    Rate = Rate or 1
    Position = Position or 0
    BlendInTime = BlendInTime or 0
    BlendOutTime = BlendOutTime or 0
    LoopCount = LoopCount or 1
    EndPosition = EndPosition or 0
    bStopAllMontages = bStopAllMontages or false
    SlotName = SlotName or "DefaultSlot"
    return AnimComp:PlayAnimByName(Name, Rate, Position, BlendInTime, BlendOutTime, LoopCount, EndPosition, LinkedTag, bStopAllMontages, SlotName)
  else
    Log.Warning("[SceneCharacter:PlayAnim] cant find URocoAnimComponent")
  end
  return 0
end

function SceneCharacter:PlayAdditiveAnim(Name, Rate, BlendInTime, BlendOutTime)
  local AnimComp = self:GetAnimComponent()
  if AnimComp then
    Rate = Rate or 1
    BlendInTime = BlendInTime or 0
    BlendOutTime = BlendOutTime or 0
    return AnimComp:PlayAdditiveAnimByName(Name, Rate, BlendInTime, BlendOutTime)
  else
    Log.Warning("[SceneCharacter:PlayAdditiveAnim] cant find URocoAnimComponent")
  end
  return 0
end

function SceneCharacter:StopAnim(Name, blendOutTime, LinkedTag)
  local AnimComp = self:GetAnimComponent()
  if AnimComp then
    blendOutTime = blendOutTime or 0
    LinkedTag = LinkedTag or "None"
    return AnimComp:StopAnimByName(Name, blendOutTime, LinkedTag)
  else
    Log.Warning("[SceneCharacter:StopAnim] cant find URocoAnimComponent")
  end
  return false
end

function SceneCharacter:StopAdditiveAnim(Name, blendOutTime)
  local AnimComp = self:GetAnimComponent()
  if AnimComp then
    blendOutTime = blendOutTime or 0
    return AnimComp:StopAdditiveAnimByName(Name, blendOutTime)
  else
    Log.Warning("[SceneCharacter:StopAdditiveAnim] cant find URocoAnimComponent")
  end
  return false
end

function SceneCharacter:PauseAnim()
  local AnimComp = self:GetAnimComponent()
  if AnimComp then
    return AnimComp:PauseCurrentAnim()
  else
    Log.Warning("[SceneCharacter:PauseAnim] cant find URocoAnimComponent")
  end
  return false
end

function SceneCharacter:ResumeAnim()
  local AnimComp = self:GetAnimComponent()
  if AnimComp then
    return AnimComp:ResumeCurrentAnim()
  else
    Log.Warning("[SceneCharacter:ResumeAnim] cant find URocoAnimComponent")
  end
  return false
end

function SceneCharacter:OverrideCurrentAnimRate(Rate)
  local AnimComp = self:GetAnimComponent()
  if AnimComp then
    return AnimComp:OverrideCurrentAnimRate(Rate or 1)
  else
    Log.Warning("[SceneCharacter:OverrideCurrentAnimRate] cant find URocoAnimComponent")
  end
  return false
end

function SceneCharacter:StopAllMontage(BlendOut)
  local AnimComp = self:GetAnimComponent()
  if AnimComp and UE.UObject.IsValid(AnimComp) then
    return AnimComp:StopAllMontage(BlendOut or 0.1)
  end
  return false
end

function SceneCharacter:SetRootMotionMode(Mode)
  local View = self.viewObj
  if not View then
    return
  end
  local Mesh = View.Mesh
  if not Mesh then
    return
  end
  local AnimInst = Mesh:GetAnimInstance()
  if not AnimInst then
    return
  end
  AnimInst:SetRootMotionMode(Mode)
end

function SceneCharacter:SetNPCGravity(gravityScale)
  if UE.UObject.IsValid(self.viewObj) then
    local moveCmpt = self.viewObj:GetComponentByClass(UE4.UCharacterMovementComponent)
    if moveCmpt then
      moveCmpt.GravityScale = gravityScale
    end
  end
end

function SceneCharacter:GetServerPoint(Point)
  local Pos = self:GetActorLocation()
  if not Pos then
    return nil
  end
  local Rot = self:GetActorRotation()
  if not Rot then
    return nil
  end
  Point = Point or ProtoMessage:newPoint()
  if Pos.X ~= Pos.X then
    Pos.X = 0
  end
  if Pos.Y ~= Pos.Y then
    Pos.Y = 0
  end
  if Pos.Z ~= Pos.Z then
    Pos.Z = 0
  end
  Point.pos.x = math.round(Pos.X)
  Point.pos.y = math.round(Pos.Y)
  Point.pos.z = math.round(Pos.Z)
  Point.dir.z = math.round((Rot.Yaw or 0) * 10)
  Point.dir.x = math.round((Rot.Roll or 0) * 10)
  Point.dir.y = math.round((Rot.Pitch or 0) * 10)
  return Point
end

function SceneCharacter:GetServerPosition(Position)
  local Pos = self:GetActorLocation()
  if not Pos then
    return nil
  end
  Position = Position or ProtoMessage:newPosition()
  Position.x = math.round(Pos.X)
  Position.y = math.round(Pos.Y)
  Position.z = math.round(Pos.Z)
  return Position
end

function SceneCharacter:GetSetNpcPosItem()
  local Item = _G.ProtoMessage:newSetNpcPosItem()
  Item.npc_id = self.serverData.base.actor_id
  Item.npc_logic_id = self.serverData.base.logic_id
  self:GetServerPoint(Item.pt)
  return Item
end

function SceneCharacter:DistanceTo(OtherActor, IgnoreZ, Squared)
  if OtherActor then
    local MyLocation = self:GetActorLocation()
    local OtherLocation = OtherActor:GetActorLocation()
    if not OtherLocation then
      Log.Error("SceneCharacter:DistanceTo() OtherActor Location is null")
      return 0
    end
    local DX = MyLocation.X - OtherLocation.X
    local DY = MyLocation.Y - OtherLocation.Y
    local SquaredDelta = DX * DX + DY * DY
    if not IgnoreZ then
      local DZ = MyLocation.Z - OtherLocation.Z
      SquaredDelta = SquaredDelta + DZ * DZ
    end
    if Squared then
      return SquaredDelta
    else
      return math.sqrt(SquaredDelta)
    end
  else
    Log.Error("SceneCharacter:DistanceTo() OtherActor is null")
    return 0
  end
end

function SceneCharacter:RotationTo(OtherActor, IgnoreZ)
  if not OtherActor then
    return UE.FRotator()
  end
  local aPos = self:GetActorLocation()
  local bPos = OtherActor:GetActorLocation()
  local dir = bPos - aPos
  if IgnoreZ then
    dir.Z = 0
  end
  return dir:ToRotator():Clamp()
end

function SceneCharacter:GetSkillComponent()
  if UE.UObject.IsValid(self.viewObj) then
    return self.viewObj.RocoSkill
  end
end

function SceneCharacter:GetViewObject()
  return self.viewObj
end

function SceneCharacter:EnsurePerform()
  self:EnsureComponent(HoldingItemComponent)
  self:EnsureComponent(SkillShowComponent)
end

function SceneCharacter:PlayShowById(PerformConf, caller, callback, skillProxy, pre_start_caller, pre_start_callback, priority)
  self:EnsurePerform()
  self.SkillShowComponent:PlayPerform(self, PerformConf, caller, callback, skillProxy, pre_start_caller, pre_start_callback, priority)
end

function SceneCharacter:ModifyMoveSpeedByBuff(SpeedRate)
  self.BuffSpeedScale = SpeedRate
end

function SceneCharacter:IsVisible()
  if not self.viewObj then
    return false
  end
  if self.viewObj.bHidden then
    return false
  end
  local SkeMesh = self.viewObj:GetComponentByClass(UE4.USkeletalMeshComponent)
  if SkeMesh then
    return SkeMesh:IsVisible() and not SkeMesh.bHiddenInGame
  end
  return true
end

function SceneCharacter:GetHeadLookAtComponent()
  return self.viewObj and self.viewObj.BP_HeadLookAtComponent
end

function SceneCharacter:SetHeadLookAtActor(TargetActor, Immediately, EnableTurn)
  local HeadLookAtComponent = self:GetHeadLookAtComponent()
  if HeadLookAtComponent and HeadLookAtComponent:PreUpdateParamByType(UE4.ELookAtParamType.Target, TargetActor) then
    if GlobalConfig.LookAtLog then
      Log.Debug("SceneCharacter:SetHeadLookAtActor", TargetActor and UE.UObject.IsValid(TargetActor) and TargetActor:GetName())
    end
    HeadLookAtComponent:ResetAutoLookAt()
    if TargetActor then
      HeadLookAtComponent:SetAutoLookAtParam(UE4.ELookAtParamType.Target, TargetActor, nil, nil, nil, nil, nil, UE4.ELookAtPriority.AutoLookAt)
      HeadLookAtComponent:ActiveAutoLookAt(Immediately, "Bip001-Neck", false, not EnableTurn)
    end
  end
end

function SceneCharacter:MarkPerception(active)
  if self.viewObj and UE.UObject.IsValid(self.viewObj) then
    local perceptionActiveCount = self.viewObj.PerceptionActiveCount
    if perceptionActiveCount then
      if active then
        perceptionActiveCount = perceptionActiveCount + 1
      else
        perceptionActiveCount = math.max(0, perceptionActiveCount - 1)
      end
      self.viewObj.PerceptionActiveCount = perceptionActiveCount
    end
  end
end

return SceneCharacter

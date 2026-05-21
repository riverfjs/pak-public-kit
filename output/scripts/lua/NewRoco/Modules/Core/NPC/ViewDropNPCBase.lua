require("UnLuaEx")
local SceneUtils = require("NewRoco.Modules.Core.Scene.Common.SceneUtils")
local ProtoEnum = require("Data.PB.ProtoEnum")
local Base = require("NewRoco.Modules.Core.NPC.ViewNPCBase")
local ViewDropNPCBase = Base:Extend("ViewDropNPCBase")

function ViewDropNPCBase:Initialize(Initializer)
  Base.Initialize(self, Initializer)
  self.CachedMeshComponent = false
  self.dropFlag = false
end

function ViewDropNPCBase:LuaBeginPlay()
  Base.LuaBeginPlay(self)
  self.checkAndStartPhy = false
  self.hited = false
  self.dropTime = 0
  self.dropStartTime = 0
  self.afterHitTime = 0
  self.dropFlag = false
  self.stopCount = 0
  self.stopCountThreshold = 0.3
  self.timeOutLimit = 10
  self:SetActorTickInterval(0.1)
end

function ViewDropNPCBase:SetCollisionEnableInternal(Flag)
  local Root = self:GetMeshComponent()
  if Root and UE.UObject.IsValid(Root) and Root.SetCollisionProfileName then
    Root:SetCollisionProfileName("CreatingNPC")
    Root:SetUseCCD(true)
  end
end

function ViewDropNPCBase:StartPhysics()
  Log.Debug("ViewDropNPCBase:StartPhysics")
  local Root = self:GetMeshComponent()
  if Root then
    Root:SetCollisionProfileName("CreatingNPC")
    Root:SetSimulatePhysics(true)
  end
end

function ViewDropNPCBase:RefreshActionArea()
end

function ViewDropNPCBase:GetHalfHeight()
  local root = self:K2_GetRootComponent()
  if not root or not UE.UObject.IsValid(root) then
    return 0
  end
  local HalfHeight = 0
  if root:IsA(UE4.UStaticMeshComponent) then
    local min, max = root:GetLocalBounds()
    HalfHeight = math.abs(max.Z - min.Z) / 2
  elseif root:IsA(UE4.USkeletalMeshComponent) and not SceneUtils.IsRuntime then
    local skeletalMesh = root.SkeletalMesh
    if skeletalMesh then
      HalfHeight = math.abs(skeletalMesh:GetBounds().BoxExtent.Z)
    end
  elseif root:IsA(UE.USphereComponent) then
    HalfHeight = root:GetScaledSphereRadius()
  end
  if HalfHeight ~= HalfHeight then
    Log.Error("\230\151\160\230\179\149\232\142\183\229\143\150\229\144\136\233\128\130\231\154\132\229\141\138\233\171\152(nan)", UE.UObject.GetName(self))
    return 0
  end
  return HalfHeight
end

function ViewDropNPCBase:GetMeshComponent()
  if not self.CachedMeshComponent then
    self.CachedMeshComponent = self:K2_GetRootComponent()
  end
  return self.CachedMeshComponent
end

local CallingReceiveTick = false

function ViewDropNPCBase:ReceiveTick(DeltaSeconds)
  if CallingReceiveTick then
    return
  end
  CallingReceiveTick = true
  if Base.ReceiveTick then
    Base.ReceiveTick(self, DeltaSeconds)
  elseif self.Overridden then
    self.Overridden.ReceiveTick(self, DeltaSeconds)
  else
    CallingReceiveTick = false
    return
  end
  if not self.dropFlag then
    self:SetActorTickEnabled(false)
    self.needTick = false
    CallingReceiveTick = false
    Log.Debug("Closing Tick", UE.UObject.GetName(self))
    return
  end
  self.dropTime = self.dropTime + DeltaSeconds
  local timeOut = false
  if self.dropTime > self.timeOutLimit then
    self.stopCount = self.stopCountThreshold * 2
    timeOut = true
  end
  if not self.hited and not timeOut then
    CallingReceiveTick = false
    return
  end
  if self:GetVelocityScale() < 51 then
    self.stopCount = self.stopCount + math.min(DeltaSeconds, 0.05)
  elseif not timeOut then
    self.stopCount = 0
  end
  if self.sceneCharacter and self.sceneCharacter.bCreateFromSrcNpc then
    if timeOut or self.stopCount >= self.stopCountThreshold then
      if not self.BeamComponent.showing then
        self:PlayBeamEffect()
      end
      local MeshComp = self:GetMeshComponent()
      if MeshComp then
        MeshComp:SetPhysicsLinearVelocity(UE4Helper.ZeroVector, false, "")
        MeshComp:SetPhysicsAngularVelocity(UE4Helper.ZeroVector, false, "")
        MeshComp:SetSimulatePhysics(false)
      end
      self:SendPosToServer(_G.ProtoEnum.SetNpcPosType.SNPT_ITEM_DROP)
      self:SetActorTickEnabled(false)
      self.needTick = false
      self:OnDropStop()
    end
  elseif self.sceneCharacter then
    self:SetActorTickEnabled(false)
    self.needTick = false
    self:OnDropStop()
  end
  CallingReceiveTick = false
end

function ViewDropNPCBase:OnDropStart()
  self.dropStartTime = os.msTime()
  self.dropFlag = true
  self:SetActorTickEnabled(true)
end

function ViewDropNPCBase:GetVelocityScale()
  local MeshComp = self:GetMeshComponent()
  if MeshComp then
    local Velocity = MeshComp:GetPhysicsLinearVelocity()
    return Velocity:Size()
  end
  return 0
end

function ViewDropNPCBase:SendPosToServer(op_type, reset_pos_if_failed)
  local SceneCharacter = self.sceneCharacter
  if not SceneCharacter then
    return
  end
  SceneCharacter:ReportPosition(op_type, reset_pos_if_failed)
end

function ViewDropNPCBase:ReceiveHit(MyComp, Other, OtherComp, SelfMoved, HitLocation, HitNormal, NormalImpulse, Hit)
  if SceneUtils.debugNPCDrop and not self.hited and self.sceneCharacter and self.sceneCharacter.bCreateFromSrcNpc then
    Log.Warning("ViewDropNPCBase:ReceiveHit", Other:GetName(), self:GetDebugInfo())
  end
  self.hited = true
  local MeshComp = self:GetMeshComponent()
  if MeshComp then
    MeshComp:SetLinearDamping(MeshComp:GetLinearDamping() + 0.1)
    MeshComp:SetAngularDamping(MeshComp:GetAngularDamping() + 0.1)
  end
end

return ViewDropNPCBase

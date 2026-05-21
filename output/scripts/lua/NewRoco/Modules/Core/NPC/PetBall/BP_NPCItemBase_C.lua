require("UnLuaEx")
local Base = require("NewRoco.Modules.Core.NPC.ViewDropNPCBase")
local RocoSkillProxy = require("NewRoco.Utils.RocoSkillProxy")
local ThrowSessionStatusEnum = require("NewRoco.Modules.Core.NPC.ThrowSessionStatusEnum")
local PetBallComponent = require("NewRoco.Modules.Core.Scene.Component.Interaction.PetBallComponent")
local WeakPointRevealComponent = require("NewRoco.Modules.Core.Scene.Component.Boss.WeakPointRevealComponent")
local CatchPetComponent = require("NewRoco.Modules.Core.Scene.Component.Interaction.CatchPetComponent")
local HiddenComponent = require("NewRoco.Modules.Core.Scene.Component.Hidden.HiddenComponent")
local NPCLuaUtils = require("NewRoco.Modules.Core.NPC.NPCLuaUtils")
local SceneUtils = require("NewRoco.Modules.Core.Scene.Common.SceneUtils")

local function GetSquaredGlobalConf(key, default)
  local confID = _G.DataConfigManager.ConfigTableId.NPC_GLOBAL_CONFIG
  local conf = _G.DataConfigManager:GetGlobalConfigByKeyType(key, confID)
  if not conf then
    return default or 100
  end
  local num = conf.num
  return num * num
end

local ReleaseMaxDistance = GetSquaredGlobalConf("petrelease_distance", 4000000)
local MinimalGravity = 1400
local BP_NPCItemBase_C = Base:Extend("BP_NPCItemBase_C")

local function GetDefaultValueFromConfig(key, value)
  local Value = value
  local ConfigData = _G.DataConfigManager:GetGlobalConfigByKeyType(key, _G.DataConfigManager.ConfigTableId.NPC_GLOBAL_CONFIG)
  if ConfigData then
    Value = tonumber(ConfigData.str) or value
  end
  return Value
end

local SimulatePhysics = false
local TrailDisturb = true
local LinearDamping = 2
local AngularDamping = 0
local PET_BALL_KEY = "_ID_AUTOGENERATE_BALL0"

function BP_NPCItemBase_C:Initialize(Initializer)
  Base.Initialize(self, Initializer)
  self.startTime = 0.0
  self.flyTime = 0.0
  self.slowFlyTime = 0.0
  self.throwStarted = false
  self.floating = false
  self.floatingDistance = 0
  self.ResMap = {}
  self.BallId = nil
  self.ball_catch_speed = 0
  self.ball_recycle_speed = 0
  self.overdue_recycling_time = 0
  self.overdue_recycling_time_long = 0
  self.DelayHandler = nil
  Log.Debug("\229\146\149\229\153\156\231\144\131\231\148\159\229\145\189\229\145\168\230\156\159: \229\136\155\229\187\186", UE4.UObject.IsValid(self) and self:GetFullName())
end

function BP_NPCItemBase_C:SetThrowSession(session)
  self.timeOutLimit = 999999
  Log.Debug("\229\146\149\229\153\156\231\144\131\231\148\159\229\145\189\229\145\168\230\156\159: \231\148\177\230\138\149\230\142\183\229\136\155\229\187\186", UE4.UObject.IsValid(self) and self:GetFullName())
  if not self.ThrowSession and self.RocoSkill then
    self.RocoSkill:StopCurrentSkill()
  end
  Base.SetThrowSession(self, session)
  local player = _G.NRCModuleManager:DoCmd(_G.PlayerModuleCmd.GetPlayerByServerID, self.ThrowSession.owner_id)
  if player then
    UE.UNRCStatics.SetActorOwner(self, player.viewObj)
  end
  if session then
    self.SkeletalMesh.bReturnMaterialOnMove = true
  else
    self.SkeletalMesh.bReturnMaterialOnMove = false
  end
  if self.ThrowSession:HasPet(true) then
    local Conf = _G.DataConfigManager:GetNpcGlobalConfig("air_overlap_range_expansion")
    local SphereRadius = Conf and Conf.num or 750
    self.ActionArea:SetSphereRadius(SphereRadius, false)
  else
    local landConf = _G.DataConfigManager:GetNpcGlobalConfig("ball_land_effectiveradius")
    local skyConf = _G.DataConfigManager:GetNpcGlobalConfig("ball_sky_effectiveradius")
    local waterRadiusConf = _G.DataConfigManager:GetNpcGlobalConfig("ball_water_effectiveradius")
    local landRadius = landConf and landConf.num or 0
    local skyRadius = skyConf and skyConf.num or 0
    local waterRadius = waterRadiusConf and waterRadiusConf.num or 0
    self.ActionArea:SetSphereRadius(skyRadius, false)
    self.CommonSphere:SetSphereRadius(landRadius, false)
    self.WaterSphere:SetSphereRadius(waterRadius, false)
  end
  self.BallId = self.ThrowSession and self.ThrowSession.BallId
  self:PreLoadRes()
end

function BP_NPCItemBase_C:SetSceneCharacter(sceneCharacter)
  Base.SetSceneCharacter(self, sceneCharacter)
  self:SetCanBeBase(false)
end

function BP_NPCItemBase_C:SetCollisionEnableInternal(Flag)
  if self.ThrowSession then
    self:ToggleCollision(Flag)
  else
    Base.SetCollisionEnableInternal(self, Flag)
  end
end

function BP_NPCItemBase_C:OnThrowStart()
  if not UE.UObject.IsValid(self) then
    Log.Error("\230\138\149\230\142\183\231\137\169\229\147\129Invalid")
    return
  end
  if not self.ThrowSession then
    Log.Error("\230\136\145\231\154\132ThrowSession\229\145\162\239\188\140\229\149\138\239\188\159\230\136\145\231\154\132throwSession\229\145\162\239\188\159\239\188\159\239\188\159\239\188\159\239\188\159")
    self.DelayHandler = _G.DelayManager:DelayFrames(1, function()
      self.DelayHandler = nil
      if UE.UObject.IsValid(self) then
        self:K2_DestroyActor()
      end
    end)
    return
  end
  self.flyTime = 0.0
  self.slowFlyTime = 0.0
  self.throwStarted = true
  self:OnDropStart()
  if GlobalConfig.EnableShowBallFlyTime then
    self.startTime = UE4.UGameplayStatics.GetRealTimeSeconds(_G.UE4Helper.GetCurrentWorld())
    Log.Error("\232\181\183\233\163\158\229\149\166")
  end
  if self.sceneCharacter then
    self.sceneCharacter:SetSignificant(false, UE.ESignificanceValue.Highest)
  end
  Log.Debug("BP_NPCItemBase_C:OnThrowStart")
  if self.ThrowSession.is_local then
    Base.OnThrowStart(self)
    _G.NRCAudioManager:SetEmitterSwitch("Player", "Host", self)
  else
    _G.NRCAudioManager:SetEmitterSwitch("Player", "Else", self)
  end
  self.RocoFX:Activate(true)
  self.DropFX:Activate(true)
  local Root = self:K2_GetRootComponent()
  Root:SetSimulatePhysics(false)
  if _G.GlobalConfig.PlayBall and _G.GlobalConfig.SpinBall then
    self.ProjectileMovement.SpinAxis = _G.GlobalConfig.SpinBall
  end
  local ballActConf = self.ThrowSession and self.ThrowSession:GetThrowBallActConf()
  local TrailBounciness = ballActConf and ballActConf.projectile_bounciness or 0.3
  local TrailFriction = ballActConf and ballActConf.projectile_friction or 0.8
  self.ball_catch_speed = ballActConf.ball_catch_speed_min
  self.ball_recycle_speed = ballActConf.ball_return_speed_min
  self.overdue_recycling_time = ballActConf.speed_min_overdue_recycling / 1000
  self.overdue_recycling_time_long = ballActConf.overdue_recycling / 1000
  if TrailDisturb then
    math.randomseed(tostring(os.time()):reverse():sub(1, 6))
    local TrailBouncinessDisturb = ballActConf and ballActConf.projectile_bounciness_disturb or 0.05
    local TrailFrictionDisturb = ballActConf and ballActConf.projectile_friction_disturb or 0.05
    local BouncinessRand = (2 * math.random() - 1) * TrailBouncinessDisturb
    local FrictionRand = (2 * math.random() - 1) * TrailFrictionDisturb
    BouncinessRand = BouncinessRand - BouncinessRand % 0.001
    FrictionRand = FrictionRand - FrictionRand % 0.001
    TrailBounciness = TrailBounciness + BouncinessRand
    TrailFriction = TrailFriction + FrictionRand
  end
  self.ProjectileMovement.Bounciness = math.clamp(TrailBounciness, 0, 1)
  self.ProjectileMovement.Friction = math.clamp(TrailFriction, 0, 1)
  self.ProjectileMovement:SetUpdateMovingDistanceEnable(true)
  self.ProjectileMovement:SetUpdatedComponent(Root)
  self.ProjectileMovement:Activate(true)
  Root:SetCollisionProfileName("ThrowedItem")
  if self.ActionArea then
    self.ActionArea:SetCollisionProfileName("OverlapAllThrowedItem")
  end
  self.ThrowTrail:SetActive(true, true)
  if self.Sphere.OnComponentBeginOverlap then
    self.Sphere.OnComponentBeginOverlap:Add(self, self.OnSphereOverlap)
  end
  if self.ActionArea:IsA(UE.USphereComponent) then
    self.ActionArea.OnComponentBeginOverlap:Add(self, self.OnActionAreaOverlap)
  end
  if self.ThrowSession and not self.ThrowSession:HasPet(true) then
    if self.CommonSphere:IsA(UE.USphereComponent) then
      self.CommonSphere.OnComponentBeginOverlap:Add(self, self.OnCommonSphereOverlap)
    end
    if self.WaterSphere:IsA(UE.USphereComponent) then
      self.WaterSphere.OnComponentBeginOverlap:Add(self, self.OnWaterSphereOverlap)
    end
  end
  local Gravity = ballActConf and ballActConf.Gravity or MinimalGravity
  self.ProjectileMovement.ProjectileGravityScale = Gravity / 1000
  if Gravity < MinimalGravity then
    self.floating = true
    self.floatingDistance = ballActConf and ballActConf.ball_fly_distance_min or 0
    self.floatingDistance = self.floatingDistance
  else
    self.floating = false
  end
  self:SetupCollisionIgnore()
end

function BP_NPCItemBase_C:OnSphereOverlap(selfComp, otherActor, otherComp, otherBodyIndex, bFromSweep, result)
  local throwSessionValid = self.ThrowSession and self.ThrowSession.isValid
  if not throwSessionValid then
    return
  end
  if not otherActor then
    return
  end
  local OtherSceneCharacter = otherActor.sceneCharacter
  if not OtherSceneCharacter then
    return
  end
  local SceneModule = _G.NRCModuleManager:GetModule("SceneModule")
  if not SceneModule then
    self:Log("\230\137\190\228\184\141\229\136\176\229\156\186\230\153\175\230\168\161\229\157\151")
    return
  end
  if SceneModule:CheckIsPlayer(OtherSceneCharacter:GetServerId()) then
    local togetherMovePlayer = self:GetAnotherTogetherMovePlayer()
    local isTogetherMovePlayer = togetherMovePlayer and togetherMovePlayer == OtherSceneCharacter
    local ownerPlayer = self:GetOwnerPlayer()
    local isOwnerPlayer = ownerPlayer and ownerPlayer == OtherSceneCharacter
    if not isOwnerPlayer and not isTogetherMovePlayer then
      self:SimulateBounce(selfComp, otherActor, otherComp, result)
    end
    return
  end
end

function BP_NPCItemBase_C:OnActionAreaOverlap(selfComp, otherActor, otherComp, otherBodyIndex, bFromSweep, result)
  local throwSessionValid = self.ThrowSession and self.ThrowSession.isValid
  if not throwSessionValid then
    return
  end
  if not otherActor and not result.Actor then
    return
  end
  otherActor = result.Actor
  local OtherSceneCharacter = otherActor.sceneCharacter
  if not OtherSceneCharacter then
    return
  end
  local SceneModule = _G.NRCModuleManager:GetModule("SceneModule")
  if not SceneModule then
    self:Log("\230\137\190\228\184\141\229\136\176\229\156\186\230\153\175\230\168\161\229\157\151")
    return
  end
  if not (SceneModule:CheckIsNpc(OtherSceneCharacter:GetServerId()) and OtherSceneCharacter.IsPet) or not OtherSceneCharacter:IsPet() then
    return
  end
  local moveComp = otherActor.GetMovementComponent and otherActor:GetMovementComponent() or nil
  if not moveComp or not moveComp:IsFlying() and not moveComp:IsFalling() and not moveComp:IsHovering() then
    return
  end
  local SelfMoved = true
  local HitLocation = result.ImpactPoint
  local HitNormal = result.ImpactNormal
  local NormalImpulse = UE.FVector(-HitNormal.X, -HitNormal.Y, -HitNormal.Z)
  if HitLocation == UE.FVector(0, 0, 0) then
    Log.Warning("\229\146\149\229\153\156\231\144\131\231\155\184\229\133\179\230\151\165\229\191\151\239\188\154\229\145\189\228\184\173\231\154\132\231\155\174\230\160\135\228\189\141\231\189\174\230\152\1750,0,0!")
    local x, y, z = self:K2_GetActorLocation_XYZ()
    HitLocation = UE.FVector(x, y, z)
  end
  if self.currHitPet and self.currHitPet ~= OtherSceneCharacter then
    return
  end
  self:ReceiveHit(selfComp, otherActor, otherComp, SelfMoved, HitLocation, HitNormal, NormalImpulse, result)
end

function BP_NPCItemBase_C:OnCommonSphereOverlap(selfComp, otherActor, otherComp, otherBodyIndex, bFromSweep, result)
  local throwSessionValid = self.ThrowSession and self.ThrowSession.isValid
  if not throwSessionValid then
    return
  end
  if self.ThrowSession:HasPet(true) then
    return
  end
  if not otherActor and not result.Actor then
    return
  end
  otherActor = result.Actor
  local OtherSceneCharacter = otherActor.sceneCharacter
  if not OtherSceneCharacter or not OtherSceneCharacter.viewObj then
    return
  end
  local SceneModule = _G.NRCModuleManager:GetModule("SceneModule")
  if not SceneModule then
    self:Log("\230\137\190\228\184\141\229\136\176\229\156\186\230\153\175\230\168\161\229\157\151")
    return
  end
  if self:TryTriggerPetCatch(selfComp, otherActor, otherComp, result) then
    return
  end
end

local EWaterState_EWS_DeepWater = UE.EWaterState.EWS_DeepWater
local EWaterState_EWS_Swimming = UE.EWaterState.EWS_Swimming

function BP_NPCItemBase_C:OnWaterSphereOverlap(selfComp, otherActor, otherComp, otherBodyIndex, bFromSweep, result)
  local throwSessionValid = self.ThrowSession and self.ThrowSession.isValid
  if not throwSessionValid then
    return
  end
  if self.ThrowSession:HasPet(true) then
    return
  end
  if not UE4.UObject.IsValid(otherActor) then
    return
  end
  local OtherSceneCharacter = otherActor.sceneCharacter
  if not OtherSceneCharacter or not OtherSceneCharacter.viewObj then
    return
  end
  local envInfo = otherActor:GetComponentByClass(UE.UCharacterEnvInfoComponent)
  local waterState = envInfo and envInfo:GetWaterState()
  if waterState and (waterState == EWaterState_EWS_DeepWater or waterState == EWaterState_EWS_Swimming) then
    Log.Debug("\230\141\149\230\141\137\230\151\165\229\191\151: \229\176\157\232\175\149\230\141\149\230\141\137\228\184\128\229\143\170\229\156\168\230\176\180\228\184\173\231\154\132\231\178\190\231\129\181: ", waterState, OtherSceneCharacter.DebugNPCNameAndID and OtherSceneCharacter:DebugNPCNameAndID())
    if self:TryTriggerPetCatch(selfComp, otherActor, otherComp, result) then
      return
    end
  end
end

function BP_NPCItemBase_C:TryTriggerPetCatch(selfComp, otherActor, otherComp, result)
  local OtherSceneCharacter = otherActor and otherActor.sceneCharacter
  if not OtherSceneCharacter then
    return false
  end
  local SceneModule = _G.NRCModuleManager:GetModule("SceneModule")
  if not SceneModule then
    self:Log("\230\137\190\228\184\141\229\136\176\229\156\186\230\153\175\230\168\161\229\157\151")
    return false
  end
  if not (SceneModule:CheckIsNpc(OtherSceneCharacter:GetServerId()) and OtherSceneCharacter.IsPet) or not OtherSceneCharacter:IsPet() then
    return false
  end
  if not OtherSceneCharacter.viewObj.AskCanEnterThrow or not OtherSceneCharacter.viewObj:AskCanEnterThrow(self, otherComp) then
    return false
  end
  local SelfMoved = true
  local HitLocation = result.ImpactPoint
  local HitNormal = result.ImpactNormal
  local NormalImpulse = UE.FVector(-HitNormal.X, -HitNormal.Y, -HitNormal.Z)
  if HitLocation == UE.FVector(0, 0, 0) then
    Log.Warning("\229\146\149\229\153\156\231\144\131\231\155\184\229\133\179\230\151\165\229\191\151\239\188\154\229\145\189\228\184\173\231\154\132\231\155\174\230\160\135\228\189\141\231\189\174\230\152\1750,0,0!\230\154\130\230\151\182\231\148\168\232\135\170\232\186\171\231\154\132\228\189\156\228\184\186\229\145\189\228\184\173\228\189\141\231\189\174\233\161\182\228\184\138")
    local x, y, z = self:K2_GetActorLocation_XYZ()
    HitLocation = UE.FVector(x, y, z)
  end
  if self.currHitPet and self.currHitPet ~= OtherSceneCharacter then
    return false
  end
  self:ReceiveHit(selfComp, otherActor, otherComp, SelfMoved, HitLocation, HitNormal, NormalImpulse, result)
  return true
end

function BP_NPCItemBase_C:StopMovement()
  if self.ThrowTrail then
    self.ThrowTrail:SetActive(false, false)
  end
  self:TogglePhysics(false)
  if self.Sphere.OnComponentBeginOverlap then
    self.Sphere.OnComponentBeginOverlap:Remove(self, self.OnSphereOverlap)
  end
  if self.ActionArea:IsA(UE.USphereComponent) then
    self.ActionArea.OnComponentBeginOverlap:Remove(self, self.OnActionAreaOverlap)
  end
  if self.CommonSphere:IsA(UE.USphereComponent) then
    self.CommonSphere.OnComponentBeginOverlap:Remove(self, self.OnCommonSphereOverlap)
  end
  if self.WaterSphere:IsA(UE4.USphereComponent) then
    self.WaterSphere.OnComponentBeginOverlap:Remove(self, self.OnWaterSphereOverlap)
  end
  self.currHitPet = nil
end

function BP_NPCItemBase_C:GetPetBallComp()
  local SceneNpc = self.sceneCharacter
  if not SceneNpc then
    return nil
  end
  local Comp = SceneNpc:EnsureComponent(PetBallComponent)
  return Comp
end

function BP_NPCItemBase_C:ReceiveHit(MyComp, Other, OtherComp, SelfMoved, HitLocation, HitNormal, NormalImpulse, Hit)
  self:StopFloating()
  local Session = self.ThrowSession
  if not Session then
    Base.ReceiveHit(self, MyComp, Other, OtherComp, SelfMoved, HitLocation, HitNormal, NormalImpulse, Hit)
    return
  end
  if not Session.is_local then
    return
  end
  Session:OnHit()
  if not Session.isValid then
    return
  end
  local OtherSceneCharacter = Other.sceneCharacter
  if OtherSceneCharacter and OtherSceneCharacter.isLocal then
    return
  end
  local hiddenComp = OtherSceneCharacter and OtherSceneCharacter:GetComponent(HiddenComponent)
  local isHidden = hiddenComp and hiddenComp:IsHidden()
  if isHidden then
    Other = OtherSceneCharacter and OtherSceneCharacter.viewObj or Other
    OtherComp = Other:K2_GetRootComponent()
  end
  local Distance = Session:GetFlyDistance()
  if not Session.bNotFirstHit and Distance > ReleaseMaxDistance * 0.04 then
    Log.Debug("\232\167\166\229\143\145\229\188\186\229\138\155\230\138\149\230\142\183 @", Distance)
    local Position = self:Abs_K2_GetActorLocation()
    local player = _G.NRCModuleManager:DoCmd(_G.PlayerModuleCmd.GetPlayerByServerID, Session.owner_id)
    if player and player.IsMagicReplayActor and player:IsMagicReplayActor() then
    else
      _G.NRCModuleManager:DoCmd(_G.NPCModuleCmd.SendSenseEvent, Position, Enum.DotsAIWorldEventType.DAWET_BALL_DROP)
    end
    Session.bNotFirstHit = true
  end
  if OtherSceneCharacter and not Other.ThrowSession then
    local ThrowType = OtherSceneCharacter.config.throwing_interact_type
    if ThrowType == Enum.THROWING_INTERACT_TYPE.TIT_WILD_PET or ThrowType == Enum.THROWING_INTERACT_TYPE.TIT_CHIEF then
      UE4.UNRCAudioManager.Get():PlaySound2DAuto(1124, "BP_NPCCharacter_C:OnThrowItemEnter Pet")
    else
      UE4.UNRCAudioManager.Get():PlaySound2DAuto(1125, "BP_NPCCharacter_C:OnThrowItemEnter NPC")
    end
    if Other.CanThrowInter and Other:CanThrowInter(self) then
      local velocity = self.ProjectileMovement.Velocity and self.ProjectileMovement.Velocity:Size() or 0
      if not self.ThrowSession:HasPet(true) and velocity < self.ball_catch_speed then
        Log.Debug("\231\162\176\230\146\158\233\128\159\229\186\166\228\184\141\229\164\159\239\188\140\230\141\149\230\141\137\229\164\177\232\180\165", velocity, self.ball_catch_speed)
        return
      end
      if Other:CanEnterThrowInter(OtherComp) then
        self:SetThrowFuncInValid()
        local WeakComponent = OtherSceneCharacter:GetComponent(WeakPointRevealComponent)
        if WeakComponent then
          WeakComponent:OnThrowItemEnter(self, OtherComp, HitLocation, HitNormal)
        else
          Other:OnThrowItemEnter(self, OtherComp, HitLocation, HitNormal)
        end
      end
      return
    end
  end
  if not Session:HasPet(true) then
    local SurfaceType = Hit and UE4.UNRCStatics.GetSurfaceType(Hit)
    if SurfaceType and SurfaceType == UE.EPhysicalSurface.SurfaceType2 then
      self:ReleaseFailedIfStop()
    end
    return
  end
  if Distance > ReleaseMaxDistance then
    self:ReleaseFailedIfStop()
    return
  end
  if Session:HasPet(true) then
    self:SetThrowFuncInValid()
  end
  local SurfaceType = UE.UNRCStatics.GetSurfaceType(Hit)
  self:CheckForOtherInteractions(SurfaceType == UE.EPhysicalSurface.SurfaceType2)
end

function BP_NPCItemBase_C:CheckForOtherInteractions(HitOnWater)
  self:ToggleCollision(false)
  local Comp = self:GetPetBallComp()
  if Comp then
    Comp:CheckForOtherInteractions(HitOnWater, self.ThrowSession)
  else
    Log.Debug("BP_NPCItemBase_C:CheckForOtherInteractions sceneCharacter not found")
  end
end

function BP_NPCItemBase_C:ThrowRecycle(Blend)
  if not UE.UObject.IsValid(self) then
    return
  end
  self.ProjectileMovement:SetActive(false, false)
  local Comp = self:K2_GetRootComponent()
  Comp:SetSimulatePhysics(false)
  Blend = true == Blend
  if self.ThrowSession then
    if self.ThrowSession:IsRecycling() or self.ThrowSession:IsBallRecycling() then
      return
    end
    if self.ThrowSession:IsDestroyed() then
      _G.NRCModuleManager:DoCmd(_G.NPCModuleCmd.DeleteThrowPetBall, self)
      return
    end
    self.ThrowSession:SetRecycling()
    if not self.ThrowSession.bThrowFailed and not self.ThrowSession:IsCatching() then
      self.ThrowSession:SendFailEndThrowReq()
    end
  end
  if self.sceneCharacter then
    self.sceneCharacter:SetNotDestroyFlag(true)
  end
  self.ThrowTrail:SetActive(true, true)
  local player
  if self.sceneCharacter.serverData then
    player = _G.NRCModuleManager:DoCmd(_G.PlayerModuleCmd.GetPlayerByServerID, self.sceneCharacter.serverData.npc_base.create_avatar_id)
  elseif self.ThrowSession and self.ThrowSession.owner_id then
    player = _G.NRCModuleManager:DoCmd(_G.PlayerModuleCmd.GetPlayerByServerID, self.ThrowSession.owner_id)
  else
    player = _G.NRCModuleManager:DoCmd(_G.PlayerModuleCmd.GET_LOCAL_PLAYER)
  end
  local playerView = player and player.viewObj
  local SkillComponent = self:GetComponentByClass(UE4.URocoSkillComponent)
  if not SkillComponent then
    SkillComponent = self:AddComponentByClass(UE4.URocoSkillComponent, false, nil, false)
    self.RocoSkill = SkillComponent
  end
  local Skill = RocoSkillProxy.Create("/Game/ArtRes/Effects/G6Skill/Yuancheng/CallBack_False_Ball", SkillComponent, PriorityEnum.Active_Player_Action)
  if not Skill then
    self:RemoveItem()
    return
  end
  Skill:SetAdditions("Blend", Blend)
  Skill:SetCaster(playerView)
  Skill:RegisterEventCallback("End", self, self.RemoveItem)
  Skill:RegisterEventCallback("PreEndAnim", self, self.RemoveItem)
  Skill:RegisterEventCallback("PreEnd", self, self.RemoveItem)
  Skill:RegisterEventCallback("Interrupt", self, self.RemoveItem)
  Skill:RegisterEventCallback("Hide", self, self.RecycleHide)
  Skill:RegisterEventCallback("Fly", self, self.StartFly)
  Skill:RegisterEventCallback("Destroy", self, self.MarkThrowDestroyed)
  Skill:RegisterEventCallback("PreStart", self, self.InjectBall)
  local PlayRate = SceneUtils.CalculateFlyBackPlayRate(self, playerView, 1.5)
  Skill:SetPlayRate(PlayRate)
  SkillComponent:StopCurrentSkill()
  Skill:PlaySkill()
end

function BP_NPCItemBase_C:InjectBall(Name, Skill)
  if not UE.UObject.IsValid(self) then
    return
  end
  if not UE.UObject.IsValid(Skill) then
    return
  end
  local BlackBoard = Skill:GetBlackboard()
  if not UE.UObject.IsValid(BlackBoard) then
    return
  end
  local Blend = Skill:GetAddition("Blend")
  if Blend then
    BlackBoard:SetValueAsString("Blend", "Blend")
  end
  BlackBoard:SetValueAsObject(PET_BALL_KEY, self)
end

function BP_NPCItemBase_C:StartFly(Name, Skill)
  self:TogglePhysics(false)
end

function BP_NPCItemBase_C:RecycleHide(Name, Skill)
  self:SetActorHiddenInGame(true)
end

function BP_NPCItemBase_C:RemoveItem(Name, Skill)
  Log.Debug("BP_NPCItemBase_C:RemoveItem")
  if Skill then
    Skill:GetBlackboard():RemoveObjectValue(PET_BALL_KEY)
  end
  if UE4.UObject.IsValid(self) then
    self:SetActorHiddenInGame(true)
  end
  if self.sceneCharacter then
    self.sceneCharacter:SetNotDestroyFlag(false)
    local ID = self.sceneCharacter:GetServerId()
    if 0 ~= ID then
      Log.Error("\229\166\130\230\158\156\232\191\153\228\184\170\229\146\149\229\153\156\231\144\131\230\152\175\229\144\142\229\143\176\228\184\139\229\143\145\231\154\132\239\188\140\233\130\163\229\174\131\229\176\177\228\184\141\230\173\163\229\184\184\228\186\134\239\188\140\232\175\183\229\145\138\232\175\137\230\153\186\228\188\159")
      _G.NRCModuleManager:DoCmd(_G.NPCModuleCmd.RemoveNPC, ID)
    end
    if self.ThrowSession then
      _G.NRCModuleManager:DoCmd(_G.NPCModuleCmd.DeleteThrowPetBall, self)
    else
      self.sceneCharacter:Destroy()
    end
  end
  self:MarkThrowDestroyed()
end

function BP_NPCItemBase_C:MarkThrowDestroyed(Name, Skill)
  if self.hitPlayerHandle then
    for _, handleId in pairs(self.hitPlayerHandle) do
      _G.DelayManager:CancelDelayById(handleId)
    end
    self.hitPlayerHandle = nil
  end
  local SceneCharacter = self.sceneCharacter
  if not SceneCharacter then
    return
  end
  local ThrowSession = SceneCharacter.ThrowSession
  if not ThrowSession then
    return
  end
  ThrowSession:SetStatus(ThrowSessionStatusEnum.Destroyed)
end

function BP_NPCItemBase_C:ReleaseFailedIfStop()
  self:SetThrowFuncInValid()
  self.ThrowSession:SendFailEndThrowReq()
end

function BP_NPCItemBase_C:MakeCollectable()
  if GlobalConfig.EnableShowBallFlyTime then
    local time = UE4.UGameplayStatics.GetRealTimeSeconds(_G.UE4Helper.GetCurrentWorld()) - self.startTime
    Log.Error("\230\146\158\229\156\176\229\149\166", time)
  end
  self.firstVisible = false
  if SimulatePhysics then
    self.ThrowTrail:SetActive(false, true)
    self.ProjectileMovement:SetActive(false, false)
    local Comp = self:K2_GetRootComponent()
    Comp:SetSimulatePhysics(true)
    Comp:SetLinearDamping(LinearDamping)
    Comp:SetAngularDamping(AngularDamping)
    self.DelayId = _G.DelayManager:DelaySeconds(2, self.OnProjectileStopped, self)
  elseif self.ProjectileMovement:IsVelocityUnderSimulationThreshold() then
    self:OnProjectileStopped()
  else
    self.ProjectileMovement.OnProjectileStop:Clear()
    self.ProjectileMovement.OnProjectileStop:Add(self, self.OnProjectileStopped)
  end
end

function BP_NPCItemBase_C:OnProjectileStopped()
  self.ThrowSession:SetIsValid(false)
  if SimulatePhysics then
    local Comp = self:K2_GetRootComponent()
    Comp:SetSimulatePhysics(false)
  end
  self.ProjectileMovement.OnProjectileStop:Clear()
  self.ThrowSession:SetWaitBeginDrop()
  self.ThrowSession:SendEndThrowReq(self, self.OnBecomeCollectable, self:Abs_K2_GetActorLocation(), self.ProjectileMovement:GetMovingDistance())
end

function BP_NPCItemBase_C:GetBallFlyDistance()
  if self.ProjectileMovement then
    return self.ProjectileMovement:GetMovingDistance()
  end
  return 0
end

function BP_NPCItemBase_C:OnBecomeCollectable(rsp)
  if 0 ~= rsp.ret_info.ret_code then
    self:ThrowRecycle()
    return nil
  end
  if rsp.throw_bagitem_result and rsp.throw_bagitem_result.is_broken then
    self:BreakItself()
    return nil
  end
end

function BP_NPCItemBase_C:TogglePhysics(on)
  Base.TogglePhysics(self, on)
  self:ToggleCollision(on)
  self:ToggleMovement(on)
end

function BP_NPCItemBase_C:ToggleCollision(on)
  local Root = self:K2_GetRootComponent()
  if not Root then
    return
  end
  if on then
    Root:SetCollisionProfileName("ThrowedItem")
  else
    Root:SetCollisionProfileName("NPCCharacterFreeNoInteract")
  end
end

function BP_NPCItemBase_C:ToggleMovement(on)
  if not self.ProjectileMovement then
    return
  end
  if not UE.UObject.IsValid(self.ProjectileMovement) then
    return
  end
  if on then
    self.ProjectileMovement:Activate(true)
  else
    self.ProjectileMovement:Deactivate()
  end
end

function BP_NPCItemBase_C:Init()
  Base.Init(self)
  self:ToggleMovement(false)
end

function BP_NPCItemBase_C:Recycle()
  self.ProjectileMovement.OnProjectileStop:Clear()
  self.SkeletalMesh:Stop()
  self.SkeletalMesh:SetAnimation(nil)
  self.SkeletalMesh.bReturnMaterialOnMove = true
  self:TogglePhysics(false)
  self.ThrowSession = nil
  if self.DropFX.Deactivate then
    self.DropFX:Deactivate()
  else
    Log.Error("\230\137\190\228\184\141\229\136\176DropFX\231\154\132Deactivate")
  end
  if self.DelayId then
    _G.DelayManager:CancelDelayById(self.DelayId)
    self.DelayId = nil
  end
  self.RocoFX:Deactivate()
  self.ThrowTrail:Deactivate()
  self:CleanupFX()
  local RootComponent = self:K2_GetRootComponent()
  if UE.UObject.IsValid(RootComponent) then
    RootComponent:ClearMoveIgnoreActors()
  end
  Base.Recycle(self)
end

function BP_NPCItemBase_C:CleanupFX()
  local Comps = self:K2_GetComponentsByClass(UE.UParticleSystemComponent)
  for Index, Comp in tpairs(Comps) do
    if Comp ~= self.ThrowTrail and Comp ~= self.Icon_Drop then
      Comp:Deactivate()
      Comp:DetachFromParent(false, false)
    end
  end
end

function BP_NPCItemBase_C:BreakItself()
  if self.ThrowSession.bIsBroken then
    return
  end
  self:ToggleCollision(false)
  local SkillComponent = self:GetComponentByClass(UE4.URocoSkillComponent)
  if not SkillComponent then
    SkillComponent = self:AddComponentByClass(UE4.URocoSkillComponent, false, UE4.FTransform(), false)
    self.RocoSkill = SkillComponent
  end
  SkillComponent:StopCurrentSkill()
  local Skill = RocoSkillProxy.Create("/Game/ArtRes/Effects/G6Skill/Buzhuo/Ball_PoShui.Ball_PoShui", SkillComponent, PriorityEnum.Active_Player_Action)
  Skill:SetCaster(self)
  Skill:RegisterEventCallback("HideBall", self, self.OnBallBreak)
  Skill:RegisterEventCallback("End", self, self.RemoveItem)
  Skill:PlaySkill()
end

function BP_NPCItemBase_C:OnBallBreak()
  self:SetActorScale3D(_G.FVectorOne * 0.01)
  self:MarkThrowDestroyed()
end

function BP_NPCItemBase_C:ReceiveTick(DeltaSeconds)
  Base.ReceiveTick(self, DeltaSeconds)
  if not self.ThrowSession then
    return
  end
  if not self.throwStarted then
    return
  end
  self.flyTime = self.flyTime + DeltaSeconds
  if self.throwStarted then
    if self.floating then
      local flyDistance = self:GetBallFlyDistance()
      if flyDistance >= self.floatingDistance then
        self:StopFloating()
      end
    end
    local velocity = self.ProjectileMovement.Velocity and self.ProjectileMovement.Velocity:Size() or 0
    if velocity < self.ball_recycle_speed then
      self.slowFlyTime = self.slowFlyTime + DeltaSeconds
    else
      self.slowFlyTime = 0
    end
    if self.flyTime > self.overdue_recycling_time_long or self.slowFlyTime > self.overdue_recycling_time and self.ThrowSession.isValid and not self.ThrowSession:HasPet(true) then
      self.flyTime = 0
      self.slowFlyTime = 0
      local catchPetComponent = self.sceneCharacter and self.sceneCharacter:GetComponent(CatchPetComponent)
      if catchPetComponent and catchPetComponent.bIsCatching then
        Log.Warning("\229\146\149\229\153\156\231\144\131\231\155\184\229\133\179\230\151\165\229\191\151: \230\141\149\230\141\137\228\184\173\239\188\140\230\154\130\230\151\182\229\133\136\228\184\141\229\155\158\230\148\182\239\188\140\233\135\141\230\150\176\232\174\161\230\151\182", self.ThrowSession and self.ThrowSession.SeqID)
        return
      end
      Log.Warning("\229\146\149\229\153\156\231\144\131\231\155\184\229\133\179\230\151\165\229\191\151: \232\182\133\230\151\182\228\191\157\229\186\149\229\155\158\230\148\182", self.ThrowSession and self.ThrowSession.SeqID)
      self.ThrowSession:SetIsValid(false)
      self.ThrowSession:RecycleAllRes()
    end
  end
end

function BP_NPCItemBase_C.ToggleSimulate(on)
  SimulatePhysics = on
end

function BP_NPCItemBase_C.SetLinearDamping(value)
  LinearDamping = value
end

function BP_NPCItemBase_C.SetAngularDamping(value)
  AngularDamping = value
end

function BP_NPCItemBase_C.EnableTrailDisturb(on)
  TrailDisturb = on
end

function BP_NPCItemBase_C:PlayBeamEffect()
  if not self.sceneCharacter.serverData then
    Base.PlayBeamEffect(self)
    return
  end
  if not self.sceneCharacter.ThrowSession then
    Base.PlayBeamEffect(self)
  else
  end
end

function BP_NPCItemBase_C:GetHalfHeight()
  return 8
end

function BP_NPCItemBase_C:SetVisibleInternal(flag)
  Base.SetVisibleInternal(self, flag)
  if not self.ProjectileMovement:IsActive() then
    self:SetActorEnableCollision(flag)
  end
end

function BP_NPCItemBase_C:StopFloating()
  if self.floating then
    self.ProjectileMovement.ProjectileGravityScale = MinimalGravity / 1000
    self.floating = false
  end
end

function BP_NPCItemBase_C:ReceiveEndPlay(Reason)
  Log.Debug("\229\146\149\229\153\156\231\144\131\231\148\159\229\145\189\229\145\168\230\156\159: \233\148\128\230\175\129", Reason, UE4.UObject.IsValid(self) and self:GetFullName())
  if self.DelayHandler then
    _G.DelayManager:CancelDelayById(self.DelayHandler)
    self.DelayHandler = nil
  end
  if self.Sphere.OnComponentBeginOverlap then
    self.Sphere.OnComponentBeginOverlap:Remove(self, self.OnSphereOverlap)
  end
  if self.ActionArea:IsA(UE.USphereComponent) then
    self.ActionArea.OnComponentBeginOverlap:Remove(self, self.OnActionAreaOverlap)
  end
  if self.CommonSphere:IsA(UE.USphereComponent) then
    self.CommonSphere.OnComponentBeginOverlap:Remove(self, self.OnCommonSphereOverlap)
  end
  if self.WaterSphere:IsA(UE4.USphereComponent) then
    self.WaterSphere.OnComponentBeginOverlap:Remove(self, self.OnWaterSphereOverlap)
  end
  self:ReleaseRes()
  Base.ReceiveEndPlay(self, Reason)
end

function BP_NPCItemBase_C:ResetPlayerBagMaterial()
  local throwSession = self.ThrowSession
  if not throwSession then
    return
  end
  local playerId = throwSession.owner_id
  if not playerId then
    return
  end
  local player = _G.NRCModuleManager:DoCmd(_G.PlayerModuleCmd.GetPlayerByServerID, playerId)
  if not player then
    return
  end
  local character = player.viewObj
  if not UE4.UObject.IsValid(character) then
    return
  end
  local mesh = character.Mesh
  if not UE4.UObject.IsValid(mesh) then
    return
  end
  local materials = mesh:GetMaterials()
  local bagMatShortName = "Bg"
  local bagMatShortNameLower = string.lower(bagMatShortName)
  for index, material in tpairs(materials) do
    if UE4.UObject.IsValid(material) then
      local materialPathName = UE4.UKismetSystemLibrary.GetPathName(material)
      local materialPathNameLower = string.lower(materialPathName)
      if string.find(materialPathNameLower, bagMatShortNameLower) and material.SetScalarParameterValue then
        material:SetScalarParameterValue("FresnelIntensity", 0)
      end
    end
  end
end

function BP_NPCItemBase_C:PreLoadRes()
  Log.Debug("BP_NPCItemBase_C:PreLoadRes Begin", self.BallId)
  if not self.BallId then
    return
  end
  NPCLuaUtils.BatchLoadBallRes(self.BallId, self, _G.PriorityEnum.Active_Player_Action)
  Log.Debug("BP_NPCItemBase_C:PreLoadRes End", self.BallId)
end

function BP_NPCItemBase_C:ReleaseRes()
  if not self.BallId then
    return
  end
  Log.Debug("BP_NPCItemBase_C:Release", self.BallId)
  NPCLuaUtils.BatchReleaseBallRes(self.BallId, self)
end

function BP_NPCItemBase_C:SimulateBounce(selfComp, otherActor, otherComp, result)
  if self.hitPlayerHandle and self.hitPlayerHandle[otherActor] ~= nil then
    return
  end
  Log.Debug("BP_NPCItemBase_C:SimulateBounce", selfComp:GetName(), otherActor:GetName(), otherComp:GetName())
  if self.ProjectileMovement and UE.UObject.IsValid(self.ProjectileMovement) and self.ProjectileMovement:IsActive() then
    self.ProjectileMovement:Bounce(result)
  end
  self:StopFloating()
  local delayId = _G.DelayManager:DelaySeconds(2.0, function()
    if not self or UE4.UObject.IsValid(self) then
      return
    end
    if not self.hitPlayerHandle then
      return
    end
    self.hitPlayerHandle[otherActor] = nil
  end)
  if not self.hitPlayerHandle then
    self.hitPlayerHandle = {}
  end
  self.hitPlayerHandle[otherActor] = delayId
end

function BP_NPCItemBase_C:QuickOverdue()
  self.overdue_recycling_time_long = self.overdue_recycling_time_long / 2
end

function BP_NPCItemBase_C:SetupCollisionIgnore()
  local player = self:GetOwnerPlayer()
  if not player then
    return
  end
  local RootComponent = self:K2_GetRootComponent()
  if not UE.UObject.IsValid(RootComponent) then
    return
  end
  local playerView = player.viewObj
  if playerView and UE.UObject.IsValid(playerView) then
    RootComponent:IgnoreActorWhenMoving(playerView, true)
  end
  local otherPlayer = player:GetAnotherTogetherMovePlayer()
  if otherPlayer then
    local otherPlayerView = otherPlayer.viewObj
    if otherPlayerView and UE.UObject.IsValid(otherPlayerView) then
      RootComponent:IgnoreActorWhenMoving(otherPlayerView, true)
    end
  end
  local RidePetBp = player:GetRidePetBP()
  if RidePetBp and UE.UObject.IsValid(RidePetBp) then
    RootComponent:IgnoreActorWhenMoving(RidePetBp, true)
  end
end

function BP_NPCItemBase_C:GetOwnerPlayer()
  local throwSession = self.ThrowSession
  if not throwSession then
    return nil
  end
  local player = _G.NRCModuleManager:DoCmd(_G.PlayerModuleCmd.GetPlayerByServerID, throwSession.owner_id)
  return player
end

function BP_NPCItemBase_C:GetAnotherTogetherMovePlayer()
  local ownerPlayer = self:GetOwnerPlayer()
  local anotherMovePlayer = ownerPlayer and ownerPlayer:GetAnotherTogetherMovePlayer()
  return anotherMovePlayer
end

return BP_NPCItemBase_C

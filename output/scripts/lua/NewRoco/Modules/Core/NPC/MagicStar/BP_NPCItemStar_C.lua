require("UnLuaEx")
local Base = require("NewRoco.Modules.Core.NPC.ViewDropNPCBase")
local SceneAIUtils = require("NewRoco.AI.SceneAIUtils")
local NPCLuaUtils = require("NewRoco.Modules.Core.NPC.NPCLuaUtils")
local PlayerModuleEvent = require("NewRoco.Modules.Core.PlayerModule.PlayerModuleEvent")
local NavigationComponent = require("NewRoco.Modules.Core.Scene.Component.Movement.NavigationComponent")
local SyncNpcActionComponent = require("NewRoco.Modules.Core.Scene.Component.Sync.SyncNpcActionComponent")
local ShieldComponent = require("NewRoco.Modules.Core.Scene.Component.Boss.ShieldComponent")
local ThrowStarSession = require("NewRoco.Modules.Core.NPC.MagicStar.ThrowStarSession")
local RocoSkillProxy = require("NewRoco.Utils.RocoSkillProxy")
local BP_NPCItemStar_C = Base:Extend("BP_NPCItemStar_C")

function BP_NPCItemStar_C:Initialize(Initializer)
  Base:Initialize(self, Initializer)
end

function BP_NPCItemStar_C:Init()
  Base.Init(self)
  self.charge_level = 1
  self.BoomRange = 1000
  self.ActionAreaRadius = 1000
  self.StarScale = 1
  self.MaxDegree = 30
  self.KineticAttenuationBaseOnHeight = 0
  self.AddStarTailCountDown = -1
  self.hit_num = 0
  self.stop = false
  self.CurrentStarData = self.StarLevelData:Get(1)
  self.NextStarData = nil
  self.charge_percent = 0
  self.throwStarted = false
  self:SetChargeMagicStarProcess(0)
  self.isCritical = false
  self.isHitShield = false
  self.criticalBone = nil
  self.EnableCppTick = false
  self.NeedLoad = false
  self.NeedBeam = false
  self.NeedExplode = false
  self.PureBlueprint = true
  self.CriticalSkillHandle = nil
  self.BreakSkillHandle = nil
  self.loadPriority = -1
  self.starBreakCount = 0
end

function BP_NPCItemStar_C:LuaBeginPlay()
  Base.LuaBeginPlay(self)
  self.bIsBroken = false
  self:SetActorHiddenInGame(false)
  self:ToggleCollision(false)
end

function BP_NPCItemStar_C:OnChildLoaded()
  if not self.throwStarted and self.NRCChildComponent:GetChildActor() and self.NRCChildComponent:GetChildActor().SetInHand then
    self.NRCChildComponent:GetChildActor():SetInHand()
  end
  if self.throwStarted and self.NRCChildComponent:GetChildActor() and self.NRCChildComponent:GetChildActor().BeginThrow then
    self.NRCChildComponent:GetChildActor():BeginThrow()
  end
end

function BP_NPCItemStar_C:SetThrowSession(session)
  Base.SetThrowSession(self, session)
  local player = _G.NRCModuleManager:DoCmd(_G.PlayerModuleCmd.GetPlayerByServerID, self.ThrowSession.owner_id)
  if not player then
    Log.Error("\230\152\159\230\152\159\233\173\148\230\179\149\230\178\161\230\156\137Owner\239\188\140\230\137\190\228\184\141\229\136\176\229\144\136\233\128\130\231\154\132\233\133\141\231\189\174")
    self.wandData = nil
  else
    local wandConf = player:GetCurWandConf()
    self.wandData = player:GetCurWandDataByMagicType(ProtoEnum.SceneMagicType.SMT_STAR)
    _G.NRCAudioManager:SetEmitterSwitch("Suit", wandConf.WandName, self, "")
    UE.UNRCStatics.SetActorOwner(self, player.viewObj)
  end
  if self.ThrowSession.is_local then
    self.loadPriority = _G.PriorityEnum.Active_Player_Throw_Res_Important
  else
    self.loadPriority = _G.PriorityEnum.Passive_3P_Throw_Res_Important
  end
  self:SetLoadPriority(self.loadPriority)
  self:PreLoad()
  local magic_star_quality = _G.NRCModuleManager:DoCmd(_G.NPCModuleCmd.GetStarMagicQuality, self.ThrowSession and self.ThrowSession.is_local)
  self.NRCChildComponent:SetBPQualityLevel(magic_star_quality)
  local path = self:GetStarBPPath()
  self.NRCChildComponent:SetPath(path)
  self.NRCChildComponent:SetWorldScale3D(UE4.FVector(1, 1, 1))
  self.StarNiagaraSystem:SetWorldScale3D(UE4.FVector(1, 1, 1))
  self.NRCChildComponent:SetAbsolute(false, false, false)
  self.ActionArea:SetAbsolute(false, false, true)
  self.StarNiagaraSystem:SetAbsolute(false, false, true)
  self.NRCChildComponent:SetAbsolute(false, false, true)
  self:SetChargeLevel(0)
end

function BP_NPCItemStar_C:SetChargeLevel(new_charge_level)
  self.charge_level = new_charge_level + 1
  if 1 == self.charge_level then
    _G.NRCAudioManager:PlaySound3DWithActorAuto(1306, self, "BP_NPCItemStar_C:SetChargeLevel")
  elseif 2 == self.charge_level then
    _G.NRCAudioManager:PlaySound3DWithActorAuto(1307, self, "BP_NPCItemStar_C:SetChargeLevel")
  elseif 3 == self.charge_level then
    _G.NRCAudioManager:PlaySound3DWithActorAuto(1308, self, "BP_NPCItemStar_C:SetChargeLevel")
  elseif 4 == self.charge_level then
    _G.NRCAudioManager:PlaySound3DWithActorAuto(1309, self, "BP_NPCItemStar_C:SetChargeLevel")
  end
  self.NextStarData = nil
  for index = 1, self.StarLevelData:Length() do
    local starData = self.StarLevelData:Get(index)
    if index == self.charge_level then
      self.CurrentStarData = starData
    elseif index == self.charge_level + 1 then
      self.NextStarData = starData
    end
  end
  self:SetChargeMagicStarProcess(0)
  self:PreLoadWithLevel()
  self:ApplyCurrentChargeLevel()
end

function BP_NPCItemStar_C:SetChargeMagicStarProcess(chargePercent)
  self.charge_percent = chargePercent
  if self.CurrentStarData == nil then
    return
  end
  local currentRot = self.CurrentStarData.MagicStarRotation
  local currentScale = self.CurrentStarData.MagicStarScale
  local nextRot = currentRot
  local nextScale = currentScale
  if nil ~= self.NextStarData then
    nextRot = self.NextStarData.MagicStarRotation
    nextScale = self.NextStarData.MagicStarScale
  end
  self.StarScale = currentScale + (nextScale - currentScale) * chargePercent
end

function BP_NPCItemStar_C:ApplyCurrentChargeLevel()
  if not self.CurrentStarData then
    if not self.StarLevelData then
      Log.Error("Star Level Data Is None??????")
      return
    end
    if self.StarLevelData:Get(1) then
      Log.Error("Apply Current Charge Level Again")
      self.CurrentStarData = self.StarLevelData:Get(1)
    else
      Log.Error("Why?????? Get StarLevelData 1 failed")
      return
    end
  end
  self.BoomRange = self.CurrentStarData.BoomRange
  self.ActionAreaRadius = self.CurrentStarData.ActionAreaRadius
  local MagicBaseConf = _G.DataConfigManager:GetMagicBaseConf(1)
  if MagicBaseConf then
    local rawBoomRange = SceneAIUtils.ParseMagicParamByLevel(MagicBaseConf, self.charge_level - 1, self.charge_percent, 0, 2)
    if rawBoomRange and rawBoomRange > 0 then
      self.BoomRange = rawBoomRange
    end
  end
  self.MaxDegree = self.CurrentStarData.MaxDegree
  self.KineticAttenuationBasedOnHeight = self.CurrentStarData.KineticAttenuationBasedOnHeight
  self.ProjectileMovement.MaxDegree = self.MaxDegree
  self.ProjectileMovement.KineticAttenuationBasedOnHeight = self.KineticAttenuationBasedOnHeight
  local scale = UE4.FVector(self.StarScale, self.StarScale, self.StarScale)
  self:SetActorScale3D(scale)
  self.NRCChildComponent:SetWorldScale3D(scale)
end

function BP_NPCItemStar_C:OnThrowStart()
  Base.OnThrowStart(self)
  if not self.throwStarted and self.NRCChildComponent:GetChildActor() and self.NRCChildComponent:GetChildActor().SetInHand then
    self.NRCChildComponent:GetChildActor():SetInHand()
  end
  if self.NRCChildComponent:GetChildActor() and self.NRCChildComponent:GetChildActor().BeginThrow then
    self.NRCChildComponent:GetChildActor():BeginThrow()
  end
  if not self.ThrowSession.is_local then
    local bInBattle = _G.BattleManager.isInBattle or false
    if bInBattle then
      _G.NRCModuleManager:DoCmd(_G.NPCModuleCmd.DeleteThrowStar, self.sceneCharacter)
      return
    end
    local player = _G.NRCModuleManager:DoCmd(_G.PlayerModuleCmd.GetPlayerByServerID, self.ThrowSession.owner_id)
    if player and player.viewObj and player.viewObj:GetActorHidden() then
      _G.NRCModuleManager:DoCmd(_G.NPCModuleCmd.DeleteThrowStar, self.sceneCharacter)
      return
    end
  end
  _G.NRCAudioManager:PlaySound3DWithActorAuto(1356, self, "BP_NPCItemStar_C:BeginThrow")
  _G.NRCAudioManager:PlaySound3DWithActorAuto(1310, self, "BP_NPCItemStar_C:BeginThrow")
  _G.NRCAudioManager:PlaySound3DWithActorAuto(1311, self, "BP_NPCItemStar_C:BeginThrow")
  self.RocoFX:Activate(true)
  local drop_fx_quality = _G.NRCModuleManager:DoCmd(_G.NPCModuleCmd.GetStarMagicQuality, self.ThrowSession and self.ThrowSession.is_local)
  if 2 == drop_fx_quality then
    self.DropFX:Activate(true)
  else
    self.DropFX:Activate(false)
  end
  self.throwStarted = true
  self.StarScale = self.StarScale * 3
  self:ApplyCurrentChargeLevel()
  local Root = self:K2_GetRootComponent()
  Root:SetSimulatePhysics(false)
  self.ProjectileMovement:SetUpdateMovingDistanceEnable(true)
  self.ProjectileMovement:SetUpdatedComponent(Root)
  self.ProjectileMovement:Activate(true)
  if self.ThrowSession.is_local then
    self.ThrowSession:OnBeginThrow()
  end
  self.AddStarTailCountDown = 1
  _G.UpdateManager:Register(self)
  self:SetStarTrail()
  self:ToggleCollision(true)
  local player = _G.NRCModuleManager:DoCmd(_G.PlayerModuleCmd.GetPlayerByServerID, self.ThrowSession.owner_id)
  local playerView = player and player.viewObj
  if playerView then
    self.beginPos = self:K2_GetActorLocation()
  else
    self.beginPos = nil
  end
  self.ActionArea:SetSphereRadius(self.ActionAreaRadius, false)
  if self.ActionArea:IsA(UE.USphereComponent) then
    self.ActionArea.OnComponentBeginOverlap:Add(self, self.OnActionAreaOverlap)
  end
  if self.Sphere and self.Sphere:IsA(UE4.USphereComponent) then
    self.Sphere.OnComponentBeginOverlap:Add(self, self.OnSphereOverlap)
  end
end

function BP_NPCItemStar_C:OnActionAreaOverlap(selfComp, otherActor, otherComp, otherBodyIndex, bFromSweep, result)
  if not otherActor then
    return
  end
  Log.Debug("BP_NPCItemStar_C:OnActionAreaOverlap", otherActor:GetFullName())
  if not self.throwStarted then
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
  if not (SceneModule:CheckIsNpc(OtherSceneCharacter:GetServerId()) and OtherSceneCharacter.IsPet) or not OtherSceneCharacter:IsPet() then
    return
  end
  if OtherSceneCharacter:IsAThrownPet() then
    return
  end
  local moveComp = otherActor.GetMovementComponent and otherActor:GetMovementComponent() or nil
  if not moveComp or not moveComp:IsFlying() and not moveComp:IsFalling() then
    return
  end
  local SelfMoved = true
  local HitLocation = result.ImpactPoint
  if not HitLocation then
    HitLocation = UE.FVector(0, 0, 0)
  else
    HitLocation = UE.FVector(HitLocation.X, HitLocation.Y, HitLocation.Z)
  end
  local HitNormal = result.ImpactNormal
  local NormalImpulse = UE.FVector(-HitNormal.X, -HitNormal.Y, -HitNormal.Z)
  if HitLocation == UE.FVector(0, 0, 0) then
    self.currHitPet = OtherSceneCharacter
    UE.UNRCStatics.ApplyPrimitiveComponentSweep(self.ActionArea, self.ProjectileMovement.Velocity)
    return
  end
  if self.currHitPet and self.currHitPet ~= OtherSceneCharacter then
    return
  end
  self:ReceiveHit(selfComp, otherActor, otherComp, SelfMoved, HitLocation, HitNormal, NormalImpulse, result)
end

function BP_NPCItemStar_C:OnSphereOverlap(selfComp, OtherActor, otherComp, otherBodyIndex, bFromSweep, result)
  if not self.throwStarted then
    return
  end
  local player_actor = OtherActor:Cast(UE4.ARocoPlayerBase)
  if OtherActor.sceneCharacter and OtherActor.sceneCharacter.IsMagicReplayActor and OtherActor.sceneCharacter:IsMagicReplayActor() then
    return
  end
  local AttackedPlayer = player_actor and player_actor.sceneCharacter
  if player_actor and AttackedPlayer then
    if not self.ThrowSession then
      return
    end
    local player = _G.NRCModuleManager:DoCmd(_G.PlayerModuleCmd.GetPlayerByServerID, self.ThrowSession.owner_id)
    if player == AttackedPlayer then
      return
    end
    if player and player.IsMagicReplayActor and player:IsMagicReplayActor() then
      return
    end
    if self:ShouldIgnore(AttackedPlayer) then
      return
    end
    self.hit_num = self.hit_num + 1
    if result and result.ImpactPoint and result.ImpactPoint:IsNearlyZero(0.1) then
      self:K2_SetActorLocation(result.ImpactPoint, false, nil, false)
    end
    self:StarBounceEnd(self:K2_GetActorLocation(), OtherActor)
    if self:ShouldTriggerAttacked(AttackedPlayer) then
      local local_player = _G.NRCModuleManager:DoCmd(_G.PlayerModuleCmd.GET_LOCAL_PLAYER)
      if local_player == AttackedPlayer then
        local direction = UE4.UKismetMathLibrary.Subtract_VectorVector(AttackedPlayer:GetActorLocation(), self:Abs_K2_GetActorLocation())
        direction.Z = 0
        direction:Normalize()
        AttackedPlayer.viewObj.BP_ALSComponent:GetAttacked(direction)
      else
        local direction = UE4.UKismetMathLibrary.Subtract_VectorVector(AttackedPlayer:GetActorLocation(), self:Abs_K2_GetActorLocation())
        direction.Z = 0
        direction:Normalize()
        AttackedPlayer.viewObj:PerformHited(_G.ProtoEnum.PlayerAttackPerformType.PAPT_Light, direction)
      end
    end
  end
  local otherSceneCharacter = OtherActor.sceneCharacter
  if otherSceneCharacter and otherSceneCharacter.config then
    if otherSceneCharacter.config.genre == _G.Enum.ClientNpcType.CNT_BOSS_SKILL_ITEM then
      local ImpactNormal = result.ImpactNormal
      local NormalImpulse = UE.FVector(-ImpactNormal.X, -ImpactNormal.Y, -ImpactNormal.Z)
      self:ReceiveHit(selfComp, OtherActor, otherComp, true, result.ImpactPoint, ImpactNormal, NormalImpulse, result)
    elseif otherSceneCharacter.IsAHomePet and otherSceneCharacter:IsAHomePet() or otherSceneCharacter.IsAThrownPet and otherSceneCharacter:IsAThrownPet() then
      local isInHome = _G.NRCModuleManager:DoCmd(_G.HomeModuleCmd.IsInHomeScene)
      if isInHome then
        local ImpactNormal = result.ImpactNormal
        local NormalImpulse = UE.FVector(-ImpactNormal.X, -ImpactNormal.Y, -ImpactNormal.Z)
        self:ReceiveHit(selfComp, OtherActor, otherComp, true, result.ImpactPoint, ImpactNormal, NormalImpulse, result)
      end
    end
  end
end

function BP_NPCItemStar_C:ShouldTriggerAttacked(player)
  local local_player = _G.NRCModuleManager:DoCmd(_G.PlayerModuleCmd.GET_LOCAL_PLAYER)
  if player == local_player then
    local InterComp = player and player.interactionComponent
    if InterComp and InterComp:HasInteractingAction() then
      Log.Debug("BP_NPCItemStar_C:ShouldTriggerAttacked", InterComp:GetInteractingActionDesc())
      return false
    end
    local NavComp = player:EnsureComponent(NavigationComponent)
    if NavComp and NavComp.isLockPlayer then
      Log.Debug("BP_NPCItemStar_C:ShouldTriggerAttacked \229\175\188\232\136\170\228\184\173")
      return false
    end
    if _G.BattleManager.isInBattle then
      Log.Debug("BP_NPCItemStar_C:ShouldTriggerAttacked \230\136\152\230\150\151\228\184\173")
      return false
    end
    if _G.DialogueModuleCmd and _G.NRCModuleManager:DoCmd(_G.DialogueModuleCmd.HasDialogue) then
      Log.Debug("BP_NPCItemStar_C:ShouldTriggerAttacked, \229\183\178\231\187\143\229\156\168\229\175\185\232\175\157\228\184\173")
      return false
    end
    if not player or not player.viewObj then
      Log.Debug("BP_NPCItemStar_C:ShouldTriggerAttacked, player do not has viewObj")
      return false
    end
  else
    local npcActionComponent = player:GetComponent(SyncNpcActionComponent)
    if npcActionComponent and npcActionComponent:IsPlaying() then
      Log.Debug("BP_NPCItemStar_C:ShouldTriggerAttacked, \231\142\169\229\174\182\230\173\163\229\156\168\232\161\168\230\188\148\228\184\173")
      return false
    end
  end
  local playerMoveComp = player.viewObj.CharacterMovement
  if player.viewObj.RidePet then
    playerMoveComp = player.viewObj.RidePet.CharacterMovement
  end
  local bHasDisableStatus = player.statusComponent:HasAnyStatus(ProtoEnum.WorldPlayerStatusType.WPST_MAGIC, ProtoEnum.WorldPlayerStatusType.WPST_RIDING, ProtoEnum.WorldPlayerStatusType.WPST_GLIDING, ProtoEnum.WorldPlayerStatusType.WPST_LANDING, ProtoEnum.WorldPlayerStatusType.WPST_RIDE_DASHING, ProtoEnum.WorldPlayerStatusType.WPST_GLIDING_ASCENDING, ProtoEnum.WorldPlayerStatusType.WPST_BALLOON_ASCENDING, ProtoEnum.WorldPlayerStatusType.WPST_AIMTHROWING, ProtoEnum.WorldPlayerStatusType.WPST_CROUCHING, ProtoEnum.WorldPlayerStatusType.WPST_BATTLE, ProtoEnum.WorldPlayerStatusType.WPST_LANNIAO_THR_ASCENDING, ProtoEnum.WorldPlayerStatusType.WPST_DEATH, ProtoEnum.WorldPlayerStatusType.WPST_DIESHA, ProtoEnum.WorldPlayerStatusType.WPST_DIESHA_DASHING, ProtoEnum.WorldPlayerStatusType.WPST_DIESHA_CLIMBING, ProtoEnum.WorldPlayerStatusType.WPST_UNRIDE, ProtoEnum.WorldPlayerStatusType.WPST_MAGIC, ProtoEnum.WorldPlayerStatusType.WPST_CLIMB, ProtoEnum.WorldPlayerStatusType.WPST_CLIMB_DASH, ProtoEnum.WorldPlayerStatusType.WPST_RIDEALL, ProtoEnum.WorldPlayerStatusType.WPST_RIDEALL_ABILITY, ProtoEnum.WorldPlayerStatusType.WPST_ROLEPLAY_BEHAVIOR, ProtoEnum.WorldPlayerStatusType.WPST_MANTLE, ProtoEnum.WorldPlayerStatusType.WPST_TRANSFORM, ProtoEnum.WorldPlayerStatusType.WPST_SPECIALMOVE)
  if bHasDisableStatus then
    Log.Debug("BP_NPCItemStar_C:ShouldTriggerAttacked, \231\142\169\229\174\182\231\138\182\230\128\129\228\184\141\229\133\129\232\174\184", table.tostring(player.statusComponent._statusDic))
    return false
  end
  return true
end

function BP_NPCItemStar_C:ReceiveHit(MyComp, Other, OtherComp, SelfMoved, HitLocation, HitNormal, NormalImpulse, Hit)
  if not self.throwStarted then
    return
  end
  local PrimComp = Other and Other:K2_GetRootComponent()
  if PrimComp and PrimComp:IsA(UE.UPrimitiveComponent) then
    PrimComp:IgnoreActorWhenMoving(self, true)
  end
  Base.ReceiveHit(self, MyComp, Other, OtherComp, SelfMoved, HitLocation, HitNormal, NormalImpulse, Hit)
  self.hit_num = self.hit_num + 1
  self:StarBounceEnd(HitLocation, Other, Hit.BoneName)
end

function BP_NPCItemStar_C:AddChargeLevel()
  self.charge_level = self.charge_level + 1
end

function BP_NPCItemStar_C:GetChargeLevel()
  return self.charge_level
end

function BP_NPCItemStar_C:SetInitialVelocity(InitVelocity)
  self.ProjectileMovement:SetInitSpeed(InitVelocity)
  self.ProjectileMovement.InitHeight = self:Abs_K2_GetActorLocation().Z
end

function BP_NPCItemStar_C:StarBounceEnd(HitLocation, OtherActor, OtherBone)
  if not UE4.UObject.IsValid(self) or not self.ProjectileMovement then
    self:OnBreakEnd()
    return
  end
  self.ProjectileMovement:SetUpdateMovingDistanceEnable(false)
  self.ProjectileMovement:Activate(false)
  self.HitInVincibleBoss = false
  if OtherActor and OtherActor.sceneCharacter then
    local shieldComponent = OtherActor.sceneCharacter:GetComponent(ShieldComponent)
    if shieldComponent and shieldComponent:IsShieldNormal() then
      self.isHitShield = true
      self.isCritical, self.criticalBone = shieldComponent:IsCriticalBone(OtherBone, self.charge_level)
      local AIComponent = OtherActor.sceneCharacter.AIComponent
      if AIComponent:HasControlFlags(_G.Enum.SceneAiControlFlags.SACF_PETBOSS_INVICIBLE) then
        self.HitInVincibleBoss = true
      end
      shieldComponent:OnHit(HitLocation, self.isCritical, self.HitInVincibleBoss)
    end
  end
  self.hitActor = OtherActor
  self:BreakItself(HitLocation)
  self.ProjectileMovement:StopSimulating(UE4.FHitResult())
  if self.ActionArea:IsA(UE.USphereComponent) then
    self.ActionArea.OnComponentBeginOverlap:Remove(self, self.OnActionAreaOverlap)
  end
  if self.Sphere:IsA(UE.USphereComponent) then
    self.Sphere.OnComponentBeginOverlap:Remove(self, self.OnSphereOverlap)
  end
end

function BP_NPCItemStar_C:BreakItself(HitLocation)
  if self.bIsBroken then
    return
  end
  self.bIsBroken = true
  self:ToggleCollision(false)
  self:K2_SetActorLocation(HitLocation, false, nil, false)
  if self.ThrowSession.is_local then
    self.ThrowSession:OnEndThrow(self.hitActor, self.criticalBone)
  end
  local bInWorldCombat = _G.NRCModuleManager:DoCmd(_G.WorldCombatModuleCmd.IsSelfInWorldCombat)
  local NiagaraSystemPath, SoundId
  if self.ThrowSession.is_local then
    if self.HitInVincibleBoss then
      NiagaraSystemPath, SoundId = self:GetBreakSkillData()
      SoundId = 13100
    elseif self.isCritical and bInWorldCombat then
      local current_time = os.clock()
      if ThrowStarSession.LastCriticalHitSeq and current_time - ThrowStarSession.LastCriticalHitTime > 3 then
        ThrowStarSession.LastCriticalHitTime = current_time
        ThrowStarSession.LastCriticalHitSeq = nil
      end
      if not ThrowStarSession.LastCriticalHitSeq then
        ThrowStarSession.LastCriticalHitTime = current_time
        ThrowStarSession.LastCriticalHitSeq = self.ThrowSession
        NiagaraSystemPath, SoundId = self:GetCriticalSkillData()
      else
        Log.Debug("\228\184\138\228\184\128\228\184\170\230\154\180\229\135\187\232\191\152\229\156\168\232\191\155\232\161\140\228\184\173\239\188\140\229\144\158\230\142\137\230\173\164\230\172\161\232\161\168\230\188\148\239\188\140\230\136\145\228\184\141\231\144\134\232\167\163\228\184\186\228\187\128\228\185\136\239\188\140\228\189\134ryca\232\175\180\232\166\129\232\191\153\230\160\183")
        self:OnStarBreak()
        self:RemoveStar()
        return
      end
      if not NiagaraSystemPath then
        Log.Error("\232\142\183\229\143\150\230\138\128\232\131\189\229\164\177\232\180\165\228\186\134\239\188\129\239\188\129\239\188\129\239\188\129", self.charge_level)
        self:OnStarBreak()
        self:RemoveStar()
        return
      end
    elseif self.isHitShield then
      NiagaraSystemPath, SoundId = self:GetBreakSkillData()
      SoundId = 131201
    else
      NiagaraSystemPath, SoundId = self:GetBreakSkillData()
    end
  else
    NiagaraSystemPath, SoundId = self:GetBreakSkillData()
  end
  self.NRCChildComponent:ClearAll()
  self.StarNiagaraSystem:ClearAll()
  local Skill = RocoSkillProxy.Create(NiagaraSystemPath, self.RocoSkill, PriorityEnum.Active_Player_Action)
  if not Skill then
    Log.Error("\229\136\155\233\128\160SkillProxy\229\164\177\232\180\165\228\186\134\239\188\129\239\188\129\239\188\129\239\188\129", self.charge_level)
    self:OnStarBreak()
    self:RemoveStar()
    return
  end
  local player = _G.NRCModuleManager:DoCmd(_G.PlayerModuleCmd.GET_LOCAL_PLAYER)
  Skill:SetCaster(player.viewObj)
  Skill:SetTargets({self})
  Skill:RegisterEventCallback("End", self, self.OnBreakEnd)
  Skill:RegisterEventCallback("PreEnd", self, self.OnBreakEnd)
  Skill:RegisterEventCallback("Interrupt", self, self.OnBreakEnd)
  Skill:PlaySkill()
  _G.NRCAudioManager:PlaySound3DWithActorAuto(SoundId, self, "StarBreak")
end

function BP_NPCItemStar_C:OnBreakEnd()
  self:OnStarBreak()
  self:RemoveStar()
end

function BP_NPCItemStar_C:OnStarBreak()
  if UE4.UObject.IsValid(self) then
    self:SetActorScale3D(_G.FVectorOne * 0.01)
    self.StarNiagaraSystem:SetHiddenInGame(true)
    self.StarNiagaraSystem:SetComponentActive(false)
  end
  self.currHitPet = nil
end

function BP_NPCItemStar_C:RemoveStar(Name, Skill)
  Log.Debug("BP_NPCItemStar_C:RemoveStar")
  if UE4.UObject.IsValid(self) then
    self:SetActorHiddenInGame(true)
  end
  if ThrowStarSession.LastCriticalHitSeq == self.ThrowSession then
    ThrowStarSession.LastCriticalHitSeq = nil
  end
  _G.NRCModuleManager:DoCmd(_G.NPCModuleCmd.DeleteThrowStar, self.sceneCharacter)
end

function BP_NPCItemStar_C:StarEarlyBroken()
end

function BP_NPCItemStar_C:SetStarTrail()
  local magic_star_quality = _G.NRCModuleManager:DoCmd(_G.NPCModuleCmd.GetStarMagicQuality, self.ThrowSession and self.ThrowSession.is_local)
  self.StarNiagaraSystem:ClearAll()
  self.StarNiagaraSystem:SetNiagaraQualityLevel(magic_star_quality)
  self.StarNiagaraSystem:SetPath(self:GetTailPath())
end

function BP_NPCItemStar_C:ToggleCollision(on)
  self.collisionEnabled = on
end

function BP_NPCItemStar_C:OnTick(DeltaTime)
  if self.AddStarTailCountDown > 0 then
    self.AddStarTailCountDown = self.AddStarTailCountDown - 1
    if self.AddStarTailCountDown <= 0 then
      self:BeginCheck()
    end
  end
  if self.throwStarted and not self.bIsBroken then
    if self:GetVelocityScale() < 2 then
      self.starBreakCount = self.starBreakCount + math.min(DeltaTime, 0.05)
    else
      self.starBreakCount = 0
    end
    if self.starBreakCount > 0.2 then
      Log.Error("\230\152\159\230\152\159\233\173\148\230\179\149\232\182\133\230\151\182\229\136\160\233\153\164")
      self:OnBreakEnd()
    end
  end
end

function BP_NPCItemStar_C:BeginCheck()
  if not self.beginPos then
    return
  end
  local currentLocation = self:K2_GetActorLocation()
  local player = _G.NRCModuleManager:DoCmd(_G.PlayerModuleCmd.GetPlayerByServerID, self.ThrowSession.owner_id)
  local playerView = player and player.viewObj
  local ignoreTable = {}
  if not playerView then
    ignoreTable = {playerView}
  end
  local antiDir = currentLocation - self.beginPos
  antiDir:Normalize()
  local beginPos = self.beginPos - antiDir * 0
  local drawDebugTrace = ThrowStarSession.ShowTrajectory and UE4.EDrawDebugTrace.ForDuration or UE4.EDrawDebugTrace.None
  local hitResults, isHit = UE4.UKismetSystemLibrary.SphereTraceMultiByProfile(self, beginPos, currentLocation, 5 * self.StarScale, "ThrowedItem", true, ignoreTable, drawDebugTrace, nil, true, UE4.FLinearColor(0, 1, 0, 1), UE4.FLinearColor(1, 1, 0, 1), 999)
  local Hited = false
  for i = hitResults:Length(), 1, -1 do
    local Hit = hitResults:Get(i)
    if Hit.bBlockingHit then
      if Hit.Actor and Hit.Actor.OnHit then
        Hit.Actor:OnHit(self)
      end
      if not Hited then
        self:StarBounceEnd(Hit.ImpactPoint)
        Hited = true
      end
      Log.Debug(string.format("\229\135\186\230\137\139\230\151\182\229\145\189\228\184\173\228\186\134 %s %s \229\175\188\232\135\180\229\142\159\229\156\176\231\136\134\231\130\184", Hit.Actor and Hit.Actor:GetFullName() or "\230\151\160Actor", Hit.Component and Hit.Component:GetFullName() or "\230\151\160Component"))
    else
      self:OnSphereOverlap(self.Sphere, Hit.Actor, Hit.Component, nil, nil, Hit)
    end
  end
end

function BP_NPCItemStar_C:OnDisappear()
  _G.NRCAudioManager:PlaySound3DWithActorAuto(1356, self, "BP_NPCItemStar_C:OnDisappear")
end

function BP_NPCItemStar_C:GetStarBPPath()
  local defaultCriticalSkill = "Blueprint'/Game/ArtRes/Effects/Particle/Scene/Staff/BallStaff/BP_Scene_BS_Main.BP_Scene_BS_Main'"
  if not self.wandData then
    return defaultCriticalSkill
  end
  return UE4.UNRCStatics.GetSoftObjPath(self.wandData.StarMagicResource.Star)
end

function BP_NPCItemStar_C:GetBreakSkillData()
  local defaultBreakSkill = "SkillBlueprint'/Game/ArtRes/Effects/Particle/Scene/Staff/BallStaff/G6_Scene_BS_Hit01.G6_Scene_BS_Hit01'"
  if not self.wandData then
    return defaultBreakSkill, 0
  end
  if 1 == self.charge_level then
    return UE4.UNRCStatics.GetSoftObjPath(self.wandData.StarMagicResource.BreakSkillLevel1), 1312
  elseif 2 == self.charge_level then
    return UE4.UNRCStatics.GetSoftObjPath(self.wandData.StarMagicResource.BreakSkillLevel2), 1313
  elseif 3 == self.charge_level then
    return UE4.UNRCStatics.GetSoftObjPath(self.wandData.StarMagicResource.BreakSkillLevel3), 1314
  elseif 4 == self.charge_level then
    return UE4.UNRCStatics.GetSoftObjPath(self.wandData.StarMagicResource.BreakSkillLevel4), 1315
  end
  Log.Error("\231\173\137\231\186\167\228\184\141\229\175\185", self.charge_level)
  return defaultBreakSkill, 0
end

function BP_NPCItemStar_C:GetCriticalSkillData()
  local defaultCriticalSkill = "SkillBlueprint'/Game/ArtRes/Effects/Particle/Scene/Staff/BallStaff/G6_Scene_BS_Attach.G6_Scene_BS_Attach'"
  if not self.wandData then
    return defaultCriticalSkill, 0
  end
  return UE4.UNRCStatics.GetSoftObjPath(self.wandData.StarMagicResource.CriticalSkill), 131202
end

function BP_NPCItemStar_C:GetTailPath()
  if not self.wandData then
    return self.StarTrail_1
  end
  if 1 == self.charge_level then
    return UE4.UNRCStatics.GetSoftObjPath(self.wandData.StarMagicResource.StarTailLevel1)
  elseif 2 == self.charge_level then
    return UE4.UNRCStatics.GetSoftObjPath(self.wandData.StarMagicResource.StarTailLevel2)
  elseif 3 == self.charge_level then
    return UE4.UNRCStatics.GetSoftObjPath(self.wandData.StarMagicResource.StarTailLevel3)
  elseif 4 == self.charge_level then
    return UE4.UNRCStatics.GetSoftObjPath(self.wandData.StarMagicResource.StarTailLevel4)
  end
  Log.Error("\231\173\137\231\186\167\228\184\141\229\175\185", self.charge_level)
  return self.StarTrail_1
end

function BP_NPCItemStar_C:PreLoad()
  local NiagaraSystemPath, SoundId = self:GetCriticalSkillData()
  self.CriticalSkillHandle = _G.NRCResourceManager:LoadResAsync(self, NiagaraSystemPath, self.loadPriority, 10, nil, nil, nil)
end

function BP_NPCItemStar_C:PreLoadWithLevel()
  if self.BreakSkillHandle then
    _G.NRCResourceManager:UnLoadRes(self.BreakSkillHandle)
  end
  local NiagaraSystemPath, SoundId = self:GetBreakSkillData()
  self.BreakSkillHandle = _G.NRCResourceManager:LoadResAsync(self, NiagaraSystemPath, self.loadPriority, 10, nil, nil, nil)
end

function BP_NPCItemStar_C:ReleaseLoad()
  if self.CriticalSkillHandle then
    _G.NRCResourceManager:UnLoadRes(self.CriticalSkillHandle)
  end
  if self.BreakSkillHandle then
    _G.NRCResourceManager:UnLoadRes(self.BreakSkillHandle)
  end
  self.CriticalSkillHandle = nil
  self.BreakSkillHandle = nil
end

function BP_NPCItemStar_C:ReceiveEndPlay()
  self:ReleaseLoad()
  if self.ThrowSession and ThrowStarSession.LastCriticalHitSeq and self.ThrowSession == ThrowStarSession.LastCriticalHitSeq then
    ThrowStarSession.LastCriticalHitSeq = self.ThrowSession
  end
  ThrowStarSession.LastCriticalHitSeq = nil
  _G.DelayManager:CancelDelay(self.OnBreakEnd)
  _G.UpdateManager:UnRegister(self)
  Base.ReceiveEndPlay(self)
end

function BP_NPCItemStar_C:ShouldIgnore(player)
  local owner_id = self.ThrowSession and self.ThrowSession.owner_id
  local owner = _G.NRCModuleManager:DoCmd(_G.PlayerModuleCmd.GetPlayerByServerID, owner_id)
  if not owner then
    return false
  end
  local InWorldCombat = _G.NRCModuleManager:DoCmd(_G.WorldCombatModuleCmd.IsPlayerInWorldCombat, owner_id)
  if not InWorldCombat then
    return false
  end
  local togetherMove2P = owner:GetAnotherTogetherMovePlayer()
  if not togetherMove2P then
    return false
  end
  if togetherMove2P == player then
    return true
  end
  return false
end

return BP_NPCItemStar_C

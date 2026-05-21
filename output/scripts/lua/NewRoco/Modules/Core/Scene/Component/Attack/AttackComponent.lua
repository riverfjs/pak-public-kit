local PlayerModuleEvent = require("NewRoco.Modules.Core.PlayerModule.PlayerModuleEvent")
local SceneAttackEnum = require("NewRoco.Modules.Core.Scene.Component.Attack.SceneAttackEnum")
local SceneAttackRegistry = require("NewRoco.Modules.Core.Scene.Component.Attack.SceneAttackRegistry")
local DialogueModuleEvent = require("NewRoco.Modules.System.Dialogue.DialogueModuleEvent")
local HomePetAttributeComponent = require("NewRoco.Modules.System.Home.HomePetFeed.HomePetAttributeComponent")
local Delegate = require("Utils.Delegate")
local AbnormalStatusComponent = require("NewRoco.Modules.Core.Scene.Component.Status.AbnormalStatus.AbnormalStatusComponent")
local ActorComponent = require("NewRoco.Modules.Core.Scene.Component.ActorComponent")
local Base = ActorComponent
local Hitbox_Path = "Blueprint'/Game/NewRoco/Modules/Core/Scene/WorldBattle/BP_WorldBattleHitBox.BP_WorldBattleHitBox_C'"
local AttackComponent = Base:Extend("AttackComponent")
AttackComponent.ResourcePriority = _G.PriorityEnum.Passive_World_AI_AttackRes
AttackComponent.State = {
  Idle = 1,
  Aiming = 2,
  Acting = 3,
  Loading = 4
}
local SceneAttackParam

function AttackComponent.CreateParam()
  return {
    AimType = 1,
    ActionType = 1,
    Target = nil,
    TargetPos = nil,
    Radius = 30,
    Predict = 0,
    Damage = 100,
    HitStrength = 100,
    PlayerHitType = 1,
    AbnormalStatus = 0,
    AbnormalDuration = 0
  }
end

function AttackComponent:Attach(owner)
  Base.Attach(self, owner)
  self.state = AttackComponent.State.Idle
  self.suspendAttacking = false
  self.delegate = Delegate()
  self.AimComp = nil
  self.ActionComp = nil
  self.HitBoxActor = nil
  self.HitBoxActorRef = nil
  self.AttackParam = nil
  self.loadCount = 0
  self.loadValid = true
end

function AttackComponent:DeAttach()
  if self.state ~= AttackComponent.State.Idle then
    self:StopAttack(false, AIDefines.ActionResult.Aborted)
  end
end

function AttackComponent:StartAttack(param, caller, callback)
  callback = callback or function()
  end
  if self.suspendAttacking or self.state ~= AttackComponent.State.Idle then
    Log.Warning("AttackComponent: already in attacking or suspended, request rejected")
    callback(caller, AIDefines.ActionResult.Rejected)
    return
  end
  self.delegate:Add(caller, callback)
  if not self.AttackParam or param.AimType ~= self.AttackParam.AimType then
    self.AimComp = SceneAttackRegistry.GetAim(param.AimType)
  end
  if not self.AttackParam or param.ActionType ~= self.AttackParam.ActionType then
    self.ActionComp = SceneAttackRegistry.GetAction(param.ActionType)
  end
  self.AttackParam = param
  if self.AimComp and self.ActionComp then
    self.state = AttackComponent.State.Loading
    self.loadCount = 3
    self.loadValid = true
    self:SelfInit()
    self.AimComp:Init(self)
    self.ActionComp:Init(self)
  else
    Log.Debug("[AttackComponent] \230\178\161\230\156\137\230\137\190\229\136\176\229\175\185\229\186\148\231\154\132\230\148\187\229\135\187\229\174\158\231\142\176,\229\143\150\230\182\136\230\148\187\229\135\187.  npc:", self.owner.name)
    self:Callee(AIDefines.ActionResult.Failed)
  end
end

function AttackComponent:SelfInit()
  self:SelfReleaseResource()
  self.hitboxClassRequest = NRCResourceManager:LoadResAsync(self, Hitbox_Path, self.ResourcePriority, 10, self.SelfLoadSucc, self.SelfLoadFailed)
end

function AttackComponent:SelfLoadSucc(req, asset)
  assert(self.hitboxClassRequest == req, "ResourceManager returns a unmatched request")
  req.asset = asset
  req.assetRef = asset and UnLua.Ref(asset)
  self:LoadFinished(true)
end

function AttackComponent:SelfLoadFailed()
  self:LoadFinished(false)
end

function AttackComponent:SelfReleaseResource()
  if self.hitboxClassRequest then
    self.hitboxClassRequest.asset = nil
    NRCResourceManager:UnLoadRes(self.hitboxClassRequest)
    self.hitboxClassRequest = nil
  end
end

function AttackComponent:LoadFinished(success)
  if self.state ~= AttackComponent.State.Loading then
    Log.Error("[AttackComponent]Not Loading")
    return
  end
  self.loadValid = self.loadValid and success
  self.loadCount = self.loadCount - 1
  if 0 == self.loadCount then
    if self.loadValid then
      self.state = AttackComponent.State.Aiming
      local param = self.AttackParam
      local Pos
      if param.TargetPos then
        Pos = param.TargetPos
      elseif param.Target then
        local targetView = param.Target.viewObj
        if targetView then
          Pos = targetView:Abs_K2_GetActorLocation()
        else
          Log.Debug("[AttackComponent] Target is not loaded", param.AimType, param.ActionType, self.owner.config.name)
          self.state = AttackComponent.State.Idle
          self:StopAttack(false, AIDefines.ActionResult.Failed)
          return
        end
      else
        Log.Debug("[AttackComponent]Neither TargetPos nor Target is provided", param.AimType, param.ActionType, self.owner.config.name)
        self.state = AttackComponent.State.Idle
        self:StopAttack(false, AIDefines.ActionResult.Failed)
        return
      end
      self:CreateHitBox(Pos)
      if not self.AimComp:OnStart(self:GetTargetContext(), self.HitBoxActor) then
        Log.Debug("[AttackComponent] StartAttack failed", param.AimType, param.ActionType, self.owner.config.name)
        self.state = AttackComponent.State.Idle
        self:StopAttack(false, AIDefines.ActionResult.Failed)
      end
    else
      Log.Debug("[AttackComponent] Load resource failed", self.owner.config.name)
      self.state = AttackComponent.State.Idle
      self:StopAttack(false, AIDefines.ActionResult.Failed)
    end
  end
end

function AttackComponent:AimEnd()
  if self.state == AttackComponent.State.Aiming then
    self.state = AttackComponent.State.Acting
    local isAttackBan = _G.FunctionBanModuleCmd and _G.NRCModuleManager:DoCmd(_G.FunctionBanModuleCmd.GetFunctionState, Enum.PlayerFunctionBanType.PFBT_BT_ATTACK, false, false)
    if isAttackBan or not self.ActionComp:OnStart(self:GetTargetContext(), self.HitBoxActor) then
      self.state = AttackComponent.State.Idle
      self:StopAttack(false, AIDefines.ActionResult.Failed)
    end
  end
end

function AttackComponent:ActEnd()
  if self.state == AttackComponent.State.Acting then
    self.state = AttackComponent.State.Idle
    self:StopAttack(false, AIDefines.ActionResult.Success)
  end
end

local a = require("Common.Coroutine.async")
local au = require("Common.Coroutine.async_util")
local LocalAttackParam = {}

function AttackComponent:OnHit(HitItem)
  if self.suspendAttacking then
    return false
  end
  if self.AttackParam.Target == HitItem then
    local player = _G.NRCModeManager:DoCmd(_G.PlayerModuleCmd.GET_LOCAL_PLAYER)
    if player == HitItem then
      local isAttackBan = _G.FunctionBanModuleCmd and _G.NRCModuleManager:DoCmd(_G.FunctionBanModuleCmd.GetFunctionState, Enum.PlayerFunctionBanType.PFBT_BT_ATTACK, false, false)
      if isAttackBan then
        return false
      end
      local playerLocation = player:GetActorLocation()
      local hurtDir = playerLocation - self.owner:GetActorLocation()
      hurtDir:Normalize()
      LocalAttackParam[1] = false
      LocalAttackParam[2] = nil
      local HitType = self.AttackParam.PlayerHitType
      local HitDamage = self.AttackParam.Damage
      if HitType == ProtoEnum.PlayerAttackPerformType.PAPT_None and 0 == HitDamage then
      else
        if self.owner:IsLogicStatus(Enum.SpaceActorLogicStatus.SALS_HOME_PET_GUARD) then
          LocalAttackParam[2] = ProtoEnum.RoleHpReduceReason.HP_REDUCE_REASON_STEAL_PREVENT
          HitType = ProtoEnum.PlayerAttackPerformType.PAPT_Heavy
        elseif self.owner.config.npc_role_type == Enum.PetRoleTypeInNPCConf.PRTINC_HOME then
          local AttrComp = self.owner:EnsureComponent(HomePetAttributeComponent)
          local playerId = player:GetServerId()
          if AttrComp:IsJustTriedAttack(playerId) then
            LocalAttackParam[2] = ProtoEnum.RoleHpReduceReason.HP_REDUCE_REASON_STEAL_INSPIRATION
            AttrComp:ClearJustTriedAttack(playerId)
            Log.Debug("\231\178\190\231\129\181\229\176\157\232\175\149\229\129\183\231\170\131\229\143\141\229\135\187", self.owner.config.name)
          end
        end
        if (HitType == ProtoEnum.PlayerAttackPerformType.PAPT_Heavy or HitType == ProtoEnum.PlayerAttackPerformType.PAPT_Normal) and player.statusComponent:HasStatus(Enum.WorldPlayerStatusType.WPST_TAKE_PHOTO) then
          HitType = ProtoEnum.PlayerAttackPerformType.PAPT_Light
        end
        local RealDamage = math.floor(self.AttackParam.Damage / 2)
        local HasInjure = 0 ~= self.AttackParam.Damage % 2
        LocalAttackParam[1] = HasInjure
        player:SendEvent(PlayerModuleEvent.ON_PLAYER_ATTACKED_BY_NPC, RealDamage, hurtDir, false, false, HitType, LocalAttackParam)
        Log.DebugFormat("[AttackComponent] OnHit triggered by %s dam=%d inj=%d type=%d", self.owner.config.name, RealDamage, HasInjure and 1 or 0, HitType)
        if HitType == ProtoEnum.PlayerAttackPerformType.PAPT_Heavy then
          _G.NRCModuleManager:DoCmd(_G.NPCModuleCmd.SendSenseEvent, playerLocation, Enum.DotsAIWorldEventType.DAWET_PLAYER_FALL)
        end
      end
      local AbnormalType = self.AttackParam.AbnormalStatus or 0
      local AbnormalDuration = self.AttackParam.AbnormalDuration or 0
      if AbnormalType > 0 then
        local abnormalComp = player:EnsureComponent(AbnormalStatusComponent)
        if abnormalComp and not abnormalComp:IsStatusActive(AbnormalType) then
          local abnormalConf = DataConfigManager:GetAbnormalStatusConf(AbnormalType)
          if abnormalConf then
            local selfPetBaseId = self.owner.GetPetbaseId and self.owner:GetPetbaseId() or 0
            if 0 ~= selfPetBaseId and table.contains(abnormalConf.whitelist_source_pet, selfPetBaseId) then
              local req = ProtoMessage:newZoneAiAttackAbnormalStatusReq()
              req.actor_id = self.owner:GetServerId()
              req.abnormal_status_info.abnormal_status_id = AbnormalType
              req.abnormal_status_info.abnormal_status_duration = math.floor(AbnormalDuration * 1000)
              Log.DebugFormat("[AttackComponent] try append abnormal status: %d, from %d.%s", AbnormalType, self.owner.config.id, self.owner.config.name)
              _G.ZoneServer:Send(_G.ProtoCMD.ZoneSvrCmd.ZONE_AI_ATTACK_ABNORMAL_STATUS_REQ, req, false, false, true)
            else
              Log.PrintScreenMsg("[AttackComponent] abnormal status not in whitelist: %d, from %d.%s", AbnormalType, self.owner.config.id, self.owner.config.name)
            end
          else
            Log.PrintScreenMsg("[AttackComponent] abnormal status component not found: %d, from %d.%s", AbnormalType, self.owner.config.id, self.owner.config.name)
          end
        else
          Log.PrintScreenMsg("[AttackComponent] abnormal status already active: %d, from %d.%s", AbnormalType, self.owner.config.id, self.owner.config.name)
        end
      end
    end
    return true
  end
  return false
end

function AttackComponent:GetTargetContext()
  if self.AttackParam.TargetPos then
    return nil
  else
    return self.AttackParam.Target
  end
end

function AttackComponent:CreateHitBox(targetPos)
  local Radius = self.AttackParam.Radius or 1
  local Scale = UE4.FVector(Radius, Radius, Radius)
  if self.HitBoxActor then
    self.HitBoxActor:Abs_K2_SetActorLocation_WithoutHit(targetPos)
    self.HitBoxActor:SetActorScale3D(Scale)
  else
    local _quat = UE4.FQuat.FromAxisAndAngle(UE4Helper.UpVector, 0)
    local _Transfom = UE4.FTransform(_quat, targetPos, Scale)
    local hitboxClass = self.hitboxClassRequest.asset
    self.HitBoxActor = UE4Helper.GetCurrentWorld():Abs_SpawnActor(hitboxClass, _Transfom)
    self.HitBoxActorRef = UnLua.Ref(self.HitBoxActor)
    self.HitBoxActor:SetActorScale3D(Scale)
  end
end

function AttackComponent:CleanUp()
  if self.AimComp then
    self.AimComp:Release()
  end
  if self.ActionComp then
    self.ActionComp:Release()
  end
  if self.HitBoxActor then
    local actor = self.HitBoxActor
    actor:K2_DestroyActor()
    actor:Release()
    self.HitBoxActor = nil
  end
  self.HitBoxActorRef = nil
  self:SelfReleaseResource()
end

function AttackComponent:StopAttack(interrupt, result)
  self:InterruptCurrentPerform()
  if not interrupt then
    self:Callee(result or AIDefines.ActionResult.Failed)
  end
  self.state = AttackComponent.State.Idle
  self:CleanUp()
end

function AttackComponent:Callee(result)
  self.delegate:Invoke(result)
  self.delegate:Clear()
end

function AttackComponent:InterruptCurrentPerform()
  local lastState = self.state
  self.state = AttackComponent.State.Idle
  if lastState == AttackComponent.State.Acting then
    self.ActionComp:OnInterrupt()
  elseif lastState == AttackComponent.State.Aiming then
    self.AimComp:OnInterrupt()
  end
end

function AttackComponent:SetSuspendAttack(bSuspend)
  self.suspendAttacking = bSuspend
  if self.suspendAttacking and self.state ~= AttackComponent.State.Idle then
    self:StopAttack(false, AIDefines.ActionResult.Aborted)
  end
end

function AttackComponent:IsAttacking()
  return self.state ~= AttackComponent.State.Idle
end

return AttackComponent

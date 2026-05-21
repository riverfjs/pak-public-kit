local NPCModuleEnum = require("NewRoco.Modules.Core.NPC.NPCModuleEnum")
local NPCModuleEvent = require("NewRoco.Modules.Core.NPC.NPCModuleEvent")
local ThrowSessionStatusEnum = require("NewRoco.Modules.Core.NPC.ThrowSessionStatusEnum")
local RocoSkillProxy = require("NewRoco.Utils.RocoSkillProxy")
local PetBornComponent = require("NewRoco.Modules.Core.Scene.Component.BornDie.PetBornComponent")
local CatchPetComponent = require("NewRoco.Modules.Core.Scene.Component.Interaction.CatchPetComponent")
local BornDieMask = ~(1 << NPCModuleEnum.NpcReasonFlags.BORN_DIE)
local Base = require("NewRoco.Modules.Core.Scene.Component.ActorComponent")
local BornDieComponent = Base:Extend("BornDieComponent")
local EnableDebugLog = false
local NpcAoiStateEnum = {
  Leaved = 0,
  Spawning = 1,
  Alive = 2,
  Dying = 3,
  PreDying = 4
}
BornDieComponent:SetMemberCount(4)

function BornDieComponent:PreCtor()
  Base.PreCtor(self)
  self.aoi_state = NpcAoiStateEnum.Leaved
  self.performing = false
  self.bEnablePerform = true
  self.BeginDiePlayed = false
  self.PostponedByTask = false
  self.PerformEndHandler = -1
end

function BornDieComponent:Attach(owner)
  Base.Attach(self, owner)
  self.BeginDiePlayed = false
  self.lockedAI = false
  local born_die_info = owner.serverData.base.born_die_info
  if born_die_info and born_die_info.is_borning then
    self.aoi_state = NpcAoiStateEnum.Spawning
    local View = self.owner.viewObj
    if not View then
      self:LockVisibilityAndAI()
    end
  elseif born_die_info and born_die_info.is_dying then
    self.aoi_state = NpcAoiStateEnum.Dying
  else
    self.aoi_state = NpcAoiStateEnum.Alive
  end
  if EnableDebugLog then
    Log.Warning("Attach", self:GetDebugMessage())
    Log.Dump(born_die_info, 3, "BornDieComponent:Attach")
  end
  self.owner:AddEventListener(self, NPCModuleEvent.VIEW_LOADED, self.OnViewLoaded)
end

function BornDieComponent:LockVisibilityAndAI()
  self.owner:SetVisibleForBornDieReason(false)
  if self.owner.AIComponent then
    self.owner.AIComponent:ForceLockForReason(true, false, AIDefines.LockReason.BORN_DIE)
  end
  if self.owner.InteractionComponent then
    self.owner.InteractionComponent:SetInteractionEnable(false, NPCModuleEnum.NpcInteractDisableFlag.BORN_DIE)
  end
end

function BornDieComponent:UnlockVisibilityAndAI()
  self.owner:SetVisibleForBornDieReason(true)
  if self.owner.AIComponent then
    self.owner.AIComponent:ForceLockForReason(false, false, AIDefines.LockReason.BORN_DIE)
    self.owner:ScheduleNextTick(0)
  end
  if self.owner.InteractionComponent then
    self.owner.InteractionComponent:SetInteractionEnable(true, NPCModuleEnum.NpcInteractDisableFlag.BORN_DIE)
  end
end

function BornDieComponent:DeAttach()
  if EnableDebugLog then
    Log.Warning("DeAttach", self:GetDebugMessage())
  end
  self.owner:RemoveEventListener(self, NPCModuleEvent.VIEW_LOADED, self.OnViewLoaded)
  if self.PerformEndHandler > 0 then
    _G.DelayManager:CancelDelayById(self.PerformEndHandler)
    self.PerformEndHandler = -1
    self:PerformEnd()
  end
end

function BornDieComponent:OnViewLoaded()
  if self.aoi_state == NpcAoiStateEnum.Spawning then
    self:OnBeginBorn()
  elseif self.aoi_state == NpcAoiStateEnum.Dying then
    self.performing = true
    self:PerformEnd()
  end
  if EnableDebugLog then
    Log.Warning("BornDieComponent:OnViewLoaded", self:GetDebugMessage())
    Log.Dump(self.owner.serverData.base.born_die_info, 3, "BornDieComponent:OnSetViewObj")
  end
end

function BornDieComponent:OnBornEnd(action)
end

function BornDieComponent:OnBeginBorn()
  local born_die_info = self.owner.serverData.base.born_die_info
  if not born_die_info then
    Log.Error("\229\144\142\229\143\176\230\178\161\230\156\137\228\184\139\229\143\145born_die_info", self.owner:DebugNPCNameAndID())
    return false
  end
  if self.owner.AIComponent then
    self.owner.AIComponent:ForceLockForReason(true, true, AIDefines.LockReason.BORN_DIE)
  end
  if self.owner.InteractionComponent then
    self.owner.InteractionComponent:SetInteractionEnable(false, NPCModuleEnum.NpcInteractDisableFlag.BORN_DIE)
  end
  if self.owner:IsHidden(NPCModuleEnum.NpcReasonFlags.SERVER_TASK) then
    Log.Debug("[TaskFlow] NPC hidden by task, skip born die", self.owner:DebugNPCNameAndID())
    self.PostponedByTask = true
    return false
  end
  self.PostponedByTask = false
  self.owner:SetNotDestroyFlag(true)
  if not self.owner:IsControlledByPlayer() then
    self.owner:SetNotDestroyFlag(false)
    if born_die_info.born_reason == _G.ProtoEnum.ClientCreatePetReason.CCPR_THROW or born_die_info.born_reason == _G.ProtoEnum.ClientCreatePetReason.CCPR_PERCEPTION or born_die_info.born_reason == _G.ProtoEnum.ClientCreatePetReason.CCPR_RIDE then
      self:UnlockVisibilityAndAI()
      born_die_info.is_skill = true
      local owner = self:GetOwner()
      _G.NRCEventCenter:DispatchEvent(_G.NRCGlobalEvent.ON_THROW_PET_CREATED, owner.viewObj)
      local petBornComponent = owner:EnsureComponent(PetBornComponent)
      self.performing = petBornComponent:PetBorn(self.PerformEnd, self)
      if self.owner.OnClientBornBegin then
        self.isSpawning = true
        self.owner:OnClientBornBegin()
      end
      return true
    end
  elseif born_die_info.born_reason == _G.ProtoEnum.ClientCreatePetReason.CCPR_THROW or born_die_info.born_reason == _G.ProtoEnum.ClientCreatePetReason.CCPR_PERCEPTION or born_die_info.born_reason == _G.ProtoEnum.ClientCreatePetReason.CCPR_RIDE then
    Log.Debug("\230\156\172\229\156\176\229\143\172\229\148\164\231\154\132\231\178\190\231\129\181\228\184\141\232\131\189\230\146\173\230\138\128\232\131\189\239\188\140\228\188\154\229\134\178\231\170\129\227\128\130\227\128\130\227\128\130\229\175\188\232\135\180End\228\186\139\228\187\182\230\156\137\229\143\175\232\131\189\231\155\145\229\144\172\228\184\141\229\136\176\227\128\130\227\128\130\227\128\130")
    self.performing = true
    self:PerformEnd()
    return
  end
  local playPosition = born_die_info.start_play_time - _G.ZoneServer:GetServerTime()
  playPosition = math.clamp(playPosition / 1000.0, 0, 10)
  local isNeedSkillStartBorn = self.owner.viewObj and self.owner.viewObj.isNeedSkillStartBorn
  local Result = self:PerformCore(born_die_info.skill_or_anim, born_die_info.is_skill, playPosition, nil, true, isNeedSkillStartBorn)
  return Result
end

function BornDieComponent:OnBeginDying(action, maxDelayTime, preDie)
  if self.BeginDiePlayed then
    Log.Debug("BornDieComponent \229\183\178\231\187\143\230\156\137\233\162\132\232\161\168\230\188\148\231\154\132\230\173\187\228\186\161\228\186\134\239\188\140")
    return false
  end
  self.BeginDiePlayed = true
  if EnableDebugLog then
    Log.Warning("OnBeginDying", self:GetDebugMessage(), table.getKeyName(ProtoEnum.ActorDieReason, action.die_reason))
  end
  if self.owner.AIComponent then
    self.owner.AIComponent:ForceLockForReason(true, false, AIDefines.LockReason.BORN_DIE)
  end
  if self.owner then
    if not preDie then
      self.owner.shouldDestroy = true
    end
    if self.owner.InteractionComponent then
      self.owner.InteractionComponent:SetInteractionEnable(false, NPCModuleEnum.NpcInteractDisableFlag.BORN_DIE)
    end
  end
  if not preDie then
    self.aoi_state = NpcAoiStateEnum.Dying
  else
    self.aoi_state = NpcAoiStateEnum.PreDying
  end
  self.owner:SetNotDestroyFlag(true)
  self.owner.bDisappearPerform = false
  self.owner.DisappearSkillPath = nil
  if action.die_reason == ProtoEnum.ActorDieReason.ACTOR_DIE_REASON_NPC_PICKUP then
    local Killer
    if action.killer then
      Killer = _G.NRCModuleManager:DoCmd(NPCModuleCmd.GetNpcByServerID, action.killer)
    end
    if not Killer or not self.owner.viewObj then
      self.performing = true
      self:PerformEnd()
      return false
    end
    self.performing = true
    self.owner.viewObj:PlayPickUpByPet(Killer, self, self.PerformEnd)
    return false
  elseif action.die_reason == ProtoEnum.ActorDieReason.ACTOR_DIE_REASON_BATTLE_REWARD then
    local KillerID = action.killer
    local Player
    if not KillerID or 0 == KillerID then
      Player = _G.NRCModuleManager:DoCmd(_G.PlayerModuleCmd.GET_LOCAL_PLAYER)
    else
      Player = _G.NRCModuleManager:DoCmd(_G.PlayerModuleCmd.GetPlayerByServerID, KillerID)
    end
    Player = Player or _G.NRCModuleManager:DoCmd(_G.PlayerModuleCmd.GET_LOCAL_PLAYER)
    if Player then
      Player:PlayPostBattleCollectEffect("/Game/ArtRes/Effects/G6Skill/SceneCaiji/G6_Scene_Collected_Bottle", nil)
    else
      Log.Error("Player\228\184\162\228\186\134...")
    end
    self.performing = true
    self:PerformEnd()
  elseif action.die_reason == ProtoEnum.ActorDieReason.ACTOR_DIE_REASON_AVATAR_PICKUP then
    local Killer
    if nil ~= action.killer then
      if 0 == action.killer then
        Killer = _G.NRCModuleManager:DoCmd(_G.PlayerModuleCmd.GET_LOCAL_PLAYER)
      else
        Killer = _G.NRCModuleManager:DoCmd(_G.PlayerModuleCmd.GetPlayerByServerID, action.killer)
      end
    end
    if not Killer or not self.owner.viewObj then
      self.performing = true
      self:PerformEnd()
      return false
    end
    self.performing = true
    local View = self.owner.viewObj
    if View and UE.UObject.IsValid(View) then
      View.bHidden = false
      View:PlayPickUpByPlayer(Killer, self, self.PerformEnd)
    else
      self:PerformEnd()
    end
    return false
  elseif action.die_reason == ProtoEnum.ActorDieReason.ACTOR_DIE_REASON_HROW_BALL_AUTO_RECLYCLE then
    if not self.owner then
      return
    end
    if self.owner.viewObj then
      self.owner.viewObj:ThrowRecycle()
    else
      local ThrowSession = self.owner.ThrowSession
      if ThrowSession then
        ThrowSession:SetStatus(ThrowSessionStatusEnum.Destroyed)
      end
    end
    return false
  elseif action.die_reason == ProtoEnum.ActorDieReason.ACTOR_DIE_REASON_RECYCLE_PET_PASSIVELY then
    local View = self.owner.viewObj
    if View then
      View:FlyBackToPlayer()
    else
      Log.Error("can't find npc")
    end
    _G.NRCModuleManager:DoCmd(_G.NPCModuleCmd.UnRegisterNPCFromModule, self.owner:GetServerId())
    return false
  elseif action.die_reason == ProtoEnum.ActorDieReason.ACTOR_DIE_REASON_HROW_BALL_CATCH or action.die_reason == ProtoEnum.ActorDieReason.ACTOR_DIE_REASON_HROW_BALL_CATCH_FAIL then
    local npc = _G.NRCModuleManager:DoCmd(_G.NPCModuleCmd.GetNpcByServerID, action.die_reason_params_64[1])
    if not npc then
      Log.Error("Cannot get pet being caught in BornDieComponent:OnBeginDying! npc id: ", string.format("%u", action.die_reason_params_64[1]))
      return false
    end
    npc:SetNotDestroyFlag(true)
    local isSuccess = action.die_reason == ProtoEnum.ActorDieReason.ACTOR_DIE_REASON_HROW_BALL_CATCH and true or false
    local caster = _G.NRCModuleManager:DoCmd(PlayerModuleCmd.GetPlayerByServerID, action.killer)
    self.owner:EnsureComponent(CatchPetComponent):PlayCaughtSkill(caster, npc, isSuccess, action.die_reason_params[1], action.die_reason_params[2])
    return false
  elseif action.die_reason == ProtoEnum.ActorDieReason.ACTOR_DIE_REASON_HROW_BALL_RELEASE_PET then
    if not self.owner:IsControlledByPlayer() then
      self.shouldDestroy = true
      self:PerformEnd()
    end
    return false
  elseif action.die_reason == _G.ProtoEnum.ActorDieReason.ACTOR_DIE_REASON_HROW_BALL_BATTLE then
    if self.owner.ThrowSession then
      self.owner.ThrowSession:SetStatus(ThrowSessionStatusEnum.Destroyed)
    end
    self.owner:SetNotDestroyFlag(false)
    return false
  elseif action.die_reason == ProtoEnum.ActorDieReason.ACTOR_DIE_REASON_HROW_BALL_BROKEN then
    self.owner.viewObj:BreakItself()
    return false
  elseif action.die_reason == ProtoEnum.ActorDieReason.ACTOR_DIE_REASON_CATCHED then
    self.owner:SetNotDestroyFlag(true)
    return false
  elseif action.die_reason == ProtoEnum.ActorDieReason.ACTOR_DIE_REASON_RECYCLE_FRIEND_RIDE_PET then
    _G.NRCModuleManager:DoCmd(_G.NPCModuleCmd.SetDiePetForFriendRideMap, action.actor_id, true)
  end
  local Result = self:PerformCore(action.skill_or_anim, action.is_skill, 0, nil, false)
  return Result
end

function BornDieComponent:PerformCore(name, isSkill, playPos, killer, isBorn, isNeedSkillStartBorn)
  if self.bEnablePerform == false then
    self.performing = true
    self:PerformEnd()
    return false
  end
  if string.IsNilOrEmpty(name) then
    self.performing = true
    self:PerformEnd()
    return false
  end
  isSkill = isSkill or false
  playPos = playPos or 0
  local view = self.owner.viewObj
  local KillerView = killer and killer.viewObj
  if not view or 0 ~= self.owner.hiddenFlag & BornDieMask then
    Log.Warning("[BornDieComponent] skipped perform")
    self.performing = true
    self:PerformEnd()
    return false
  end
  if isSkill then
    if isBorn then
      self.owner:SetVisibleForBornDieReason(false)
    end
    local skillComp = view:GetComponentByClass(UE4.URocoSkillComponent)
    skillComp = skillComp or view:AddComponentByClass(UE.URocoSkillComponent, false, UE.FTransform(), false)
    local Skill = skillComp and RocoSkillProxy.Create(name, skillComp, PriorityEnum.Passive_NPC_BornDie)
    if skillComp and Skill then
      skillComp:StopPendingSkill()
      skillComp:StopCurrentSkill()
      Skill:SetPassive(true)
      Skill:SetCaster(view)
      if self.aoi_state == NpcAoiStateEnum.Dying then
        Skill.CanInterrupt = false
      end
      if isBorn then
        Skill:RegisterEventCallback("ActionStart", self, self.OnShowOwner)
        if view.BeforeBornPerform then
          view:BeforeBornPerform()
        end
      else
        view:BeforeDestroyAnim(Skill)
      end
      Skill:RegisterEventCallback("End", self, self.PerformEnd)
      Skill:RegisterEventCallback("PreEnd", self, self.PerformEnd)
      Skill:RegisterEventCallback("PreEndAnim", self, self.PerformEnd)
      Skill:RegisterEventCallback("Interrupt", self, self.PerformEnd)
      Skill:RegisterEventCallback("ActivateFailed", self, self.PerformEnd)
      if KillerView then
        Skill:SetTargets({KillerView})
      end
      Skill:PlaySkill()
      self.performing = true
    else
      self.performing = true
      self:PerformEnd()
    end
  else
    self.performing = true
    local length = self.owner:PlayAnim(name, 1, playPos) - playPos
    if self.PerformEndHandler > 0 then
      _G.DelayManager:CancelDelayById(self.PerformEndHandler)
      self.PerformEndHandler = -1
    end
    self.PerformEndHandler = _G.DelayManager:DelaySeconds(length, self.PerformEnd, self)
  end
  return true
end

function BornDieComponent:OnShowOwner(Name, Skill)
  if self.owner then
    self.owner:SetVisibleForBornDieReason(true)
  end
end

function BornDieComponent:PerformEnd(eventName, SkillObj)
  if not self.performing then
    if EnableDebugLog then
      Log.Warning("[BornDieComponent] PerformEnd called without perform", self:GetDebugMessage())
    end
    return
  end
  if SkillObj then
    SkillObj:ClearDelegates()
  end
  self.performing = false
  self.owner:SetNotDestroyFlag(false)
  if self.aoi_state == NpcAoiStateEnum.Dying or self.shouldDestroy then
    self.aoi_state = NpcAoiStateEnum.Leaved
    _G.NRCModuleManager:DoCmd(_G.NPCModuleCmd.RemoveNPC, self.owner.serverData.base.actor_id)
    if self.owner and not self.owner.isDestroy then
      self.owner:Disappear()
    end
  elseif self.aoi_state == NpcAoiStateEnum.Spawning then
    self.aoi_state = NpcAoiStateEnum.Alive
    self.owner:SetNotDestroyFlag(false)
    if self.owner.viewObj and self.owner.viewObj.OnClientBornEnd then
      self.owner.viewObj:OnClientBornEnd()
    end
    if self.owner.OnClientBornEnd then
      self.isSpawning = false
      self.owner:OnClientBornEnd()
    end
    self:UnlockVisibilityAndAI()
    if self.owner.viewObj and self.owner.viewObj.AfterBornPerform then
      self.owner.viewObj:AfterBornPerform()
    end
    self.owner:SendEvent(NPCModuleEvent.OnBornPerformFinished, self.owner)
  else
    if self.aoi_state == NpcAoiStateEnum.Alive then
      self:UnlockVisibilityAndAI()
    else
    end
  end
  self.owner:SendEvent(NPCModuleEvent.OnBornDiePerformEnd, self.owner)
  if EnableDebugLog then
    Log.Warning("PerformEnd", self:GetDebugMessage())
  end
end

function BornDieComponent:IsAlive()
  return self.aoi_state == NpcAoiStateEnum.Alive or self.aoi_state == NpcAoiStateEnum.PreDying
end

function BornDieComponent:SetAoiState(newState)
  local changed = self.aoi_state ~= newState
  self.aoi_state = newState
  return changed
end

function BornDieComponent:GetDebugMessage()
  local state
  if self.aoi_state == NpcAoiStateEnum.Leaved then
    state = "Leaved"
  elseif self.aoi_state == NpcAoiStateEnum.Spawning then
    state = "Spawning"
  elseif self.aoi_state == NpcAoiStateEnum.Alive then
    state = "Alive"
  elseif self.aoi_state == NpcAoiStateEnum.Dying then
    state = "Dying"
  else
    state = "Unk"
  end
  return "[BornDieComponent] aoi: " .. state .. "  " .. self.owner:DebugNPCNameAndID()
end

function BornDieComponent:IsSpawning()
  return self.isSpawning
end

function BornDieComponent:IsPerforming()
  return self.performing
end

function BornDieComponent:OnBornWhenSkipping()
  if self.owner.AIComponent then
    self.owner.AIComponent:ForceLockForReason(true, true, AIDefines.LockReason.BORN_DIE)
  end
  if self.owner.InteractionComponent then
    self.owner.InteractionComponent:SetInteractionEnable(false, NPCModuleEnum.NpcInteractDisableFlag.BORN_DIE)
  end
  if self.owner:IsHidden(NPCModuleEnum.NpcReasonFlags.SERVER_TASK) then
    Log.Debug("[TaskFlow] NPC hidden by task, skip born die", self.owner:DebugNPCNameAndID())
    self.PostponedByTask = true
    return false
  end
  self.PostponedByTask = false
  self.owner:SetNotDestroyFlag(true)
  self.aoi_state = NpcAoiStateEnum.Spawning
  self.performing = true
  self:PerformEnd()
end

function BornDieComponent:OnDieWhenSkipping()
  if self.owner.AIComponent then
    self.owner.AIComponent:ForceLockForReason(true, false, AIDefines.LockReason.BORN_DIE)
  end
  if self.owner and self.owner.InteractionComponent then
    self.owner.InteractionComponent:SetInteractionEnable(false, NPCModuleEnum.NpcInteractDisableFlag.BORN_DIE)
  end
  self.aoi_state = NpcAoiStateEnum.PreDying
  self.owner:SetNotDestroyFlag(true)
  self.owner.bDisappearPerform = false
  self.owner.DisappearSkillPath = nil
  self.performing = true
  self:PerformEnd()
end

return BornDieComponent

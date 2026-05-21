local SceneUtils = require("NewRoco.Modules.Core.Scene.Common.SceneUtils")
local WorldCombatModuleEnum = require("NewRoco.Modules.System.WorldCombat.WorldCombatModuleEnum")
local NPCModuleEvent = require("NewRoco.Modules.Core.NPC.NPCModuleEvent")
local PlayerModuleEvent = require("NewRoco.Modules.Core.PlayerModule.PlayerModuleEvent")
local MainUIModuleEvent = require("NewRoco.Modules.System.MainUI.MainUIModuleEvent")
local WorldCombatModuleEvent = require("NewRoco.Modules.System.WorldCombat.WorldCombatModuleEvent")
local OverlapAwareVisibilityComponent = require("NewRoco.Modules.Core.Scene.Component.Visibility.OverlapAwareVisibilityComponent")
local WorldCombatSkillComponent = require("NewRoco.Modules.Core.Scene.Component.WorldCombat.WorldCombatSkillComponent")
local WorldCombatBuffComponent = require("NewRoco.Modules.Core.Scene.Component.WorldCombat.WorldCombatBuffComponent")
local RocoSkillProxy = require("NewRoco.Utils.RocoSkillProxy")
local NPCModuleEnum = require("NewRoco.Modules.Core.NPC.NPCModuleEnum")
local BattleEvent = require("NewRoco.Modules.Core.Battle.Common.BattleEvent")
local WorldCombatRecord = NRCClass()

function WorldCombatRecord:Ctor()
  self:Reset()
end

function WorldCombatRecord:Reset()
  self.baseInfo = {
    BossActorID = nil,
    CombatID = nil,
    BeginPlayerID = nil,
    PlayersInCombat = {},
    Phase = nil,
    CombatConfID = nil,
    CombatConf = nil
  }
  self.shieldInfo = {
    shield_value = nil,
    shield_max_value = nil,
    shield_state = WorldCombatModuleEnum.ShieldState.Hidden
  }
  self.regionInfo = {SplinePoint2D = nil, debugBlock = nil}
  self.bNightmare = false
  self.resetting = false
end

function WorldCombatRecord:IsSameWorldCombat(npcId)
  if not self.baseInfo then
    return false
  end
  return self.baseInfo.BossActorID == npcId
end

function WorldCombatRecord:IsSelfInWorldCombat()
  if not self.baseInfo then
    return false
  end
  if not self.baseInfo.PlayersInCombat then
    return false
  end
  local LocalUIN = _G.NRCModuleManager:DoCmd(_G.PlayerModuleCmd.GET_LOCAL_UIN)
  if not LocalUIN then
    return false
  end
  return table.contains(self.baseInfo.PlayersInCombat, LocalUIN)
end

function WorldCombatRecord:IsWorldCombatTarget(id)
  if not self.baseInfo then
    return false
  end
  if not self.baseInfo.PlayersInCombat then
    return false
  end
  if self.baseInfo.BossActorID ~= id then
    return false
  end
  local LocalUIN = _G.NRCModuleManager:DoCmd(_G.PlayerModuleCmd.GET_LOCAL_UIN)
  if not LocalUIN then
    return false
  end
  return table.contains(self.baseInfo.PlayersInCombat, LocalUIN)
end

function WorldCombatRecord:GetDebugInfo()
  if self.baseInfo then
    return string.format("%d %u %d %d %d %u", self.baseInfo.CombatConfID, self.baseInfo.BossActorID, self.baseInfo.BossActorID, self.baseInfo.CombatID, self.baseInfo.Phase, self.baseInfo.BeginPlayerID)
  end
  return "WorldCombatRecord nil"
end

function WorldCombatRecord.CheckSelfInThisAction(Action)
  if not Action then
    return false
  end
  local LocalUIN = _G.NRCModuleManager:DoCmd(_G.PlayerModuleCmd.GET_LOCAL_UIN)
  if not LocalUIN then
    return false
  end
  if type(Action.avatar_id) == "table" and #Action.avatar_id > 0 then
    return table.contains(Action.avatar_id, LocalUIN)
  end
  return Action.avatar_id == LocalUIN
end

function WorldCombatRecord:OnWorldCombatBegin(Action)
  if not Action then
    return
  end
  self:InternalBeginWorldCombat(Action.npc_id, Action.avatar_id, Action.world_combat_id, Action.world_combat_cfg_id, Action.world_combat_phase)
  if self:IsSelfInWorldCombat() then
    self:InternalEnterWorldCombat()
  end
end

function WorldCombatRecord:OnWorldCombatFinish(Action)
  if not Action then
    return
  end
  if self:IsSelfInWorldCombat() then
    self:InternalExitWorldCombat()
  end
  self:InternalFinishWorldCombat()
end

function WorldCombatRecord:OnWorldCombatEnter(Action)
  if not Action then
    return
  end
  if table.contains(self.baseInfo.PlayersInCombat, Action.avatar_id) then
    Log.Debug("WorldCombatRecord:OnWorldCombatEnter play has in combat", Action.avatar_id, self:GetDebugInfo())
    return
  end
  if not self.baseInfo or not self.baseInfo.BossActorID then
    Log.Debug("WorldCombatRecord:OnWorldCombatEnter. base info or BossActorID is nil, do begin", Action.npc_id, Action.avatar_id)
    self:InternalBeginWorldCombat(Action.npc_id, {
      Action.avatar_id
    }, Action.world_combat_id, Action.world_combat_cfg_id, Action.world_combat_phase)
  end
  table.insert(self.baseInfo.PlayersInCombat, Action.avatar_id)
  local LocalUIN = _G.NRCModuleManager:DoCmd(_G.PlayerModuleCmd.GET_LOCAL_UIN)
  if LocalUIN == Action.avatar_id then
    self:InternalEnterWorldCombat()
  end
end

function WorldCombatRecord:OnWorldCombatExit(Action)
  if not Action then
    return
  end
  if not table.contains(self.baseInfo.PlayersInCombat, Action.avatar_id) then
    return
  end
  table.removeValue(self.baseInfo.PlayersInCombat, Action.avatar_id)
  local LocalUIN = _G.NRCModuleManager:DoCmd(_G.PlayerModuleCmd.GET_LOCAL_UIN)
  if LocalUIN == Action.avatar_id then
    self:InternalExitWorldCombat()
  end
end

function WorldCombatRecord:OnWorldCombatPhaseUpdate(Action, Tag, BaseData)
  if not self.baseInfo then
    return
  end
  local newPhase = Action.world_combat_phase
  Log.Debug("\233\166\150\233\162\134\230\136\152\230\136\152\230\150\151\233\152\182\230\174\181\230\155\180\230\150\176 %d, previous=%d, new=%d", self.baseInfo.CombatConfID, self.baseInfo.Phase, newPhase)
  self.baseInfo.Phase = newPhase
  local Boss = _G.NRCModuleManager:DoCmd(_G.NPCModuleCmd.GetNpcByServerID, self.baseInfo.BossActorID)
  if Boss then
    local AIComp = Boss.AIComponent
    if AIComp then
      AIComp:OnWorldCombatPhaseUpdated(newPhase)
    end
  else
    Log.Error("Can't find boss to sync ai params")
  end
end

function WorldCombatRecord:InternalBeginWorldCombat(npc_id, avatar_id_list, world_combat_id, world_combat_cfg_id, world_combat_phase)
  if self.baseInfo == nil then
    self.baseInfo = {}
  end
  self.baseInfo.CombatConf = _G.DataConfigManager:GetWorldCombatConf(world_combat_cfg_id or -1)
  if not self.baseInfo.CombatConf then
    Log.Error("\230\137\190\228\184\141\229\136\176\233\166\150\233\162\134\230\136\152\233\133\141\231\189\174", npc_id, world_combat_id, world_combat_cfg_id)
    return
  end
  local Boss = _G.NRCModuleManager:DoCmd(_G.NPCModuleCmd.GetNpcByServerID, npc_id)
  self.bNightmare = SceneUtils.IsLogicStatusNightmareBossActivated(Boss)
  self.baseInfo.BossActorID = npc_id
  self.baseInfo.CombatID = world_combat_id
  self.baseInfo.Phase = world_combat_phase
  self.baseInfo.CombatConfID = world_combat_cfg_id
  if avatar_id_list and #avatar_id_list > 0 then
    self.baseInfo.BeginPlayerID = avatar_id_list[1]
    for _, avatar_id in ipairs(avatar_id_list) do
      table.insert(self.baseInfo.PlayersInCombat, avatar_id)
    end
  end
  self:SetupAirWall(self.baseInfo.CombatConf, self.bNightmare)
  self:SetAirWallVisible(true)
  local BlockConf = _G.DataConfigManager:GetBlockConf(self.baseInfo.CombatConf.block_id)
  if BlockConf then
    if not self.regionInfo.SplinePoint2D then
      self.regionInfo.SplinePoint2D = UE4.TArray(UE.FVector2D)
    else
      self.regionInfo.SplinePoint2D:Clear()
    end
    local SplinePosition = UE.FVector2D(BlockConf.position[1], BlockConf.position[2])
    if #BlockConf.spline_point > 2 then
      for _, splineData in ipairs(BlockConf.spline_point) do
        self.regionInfo.SplinePoint2D:Add(UE.FVector2D(splineData.Position[1], splineData.Position[2]) + SplinePosition)
      end
    end
  end
  self:InitBossSetting(npc_id, world_combat_phase)
  _G.NRCEventCenter:DispatchEvent(WorldCombatModuleEvent.Begin, self.baseInfo.CombatID, self.baseInfo.BossActorID)
  local Player = _G.NRCModuleManager:DoCmd(_G.PlayerModuleCmd.GET_LOCAL_PLAYER)
  if Player then
    Player:SendEvent(PlayerModuleEvent.ON_PLAYER_PERCEPED_BY_NPC, self.baseInfo.BossActorID, true)
  end
  Player:AddEventListener(self, PlayerModuleEvent.ON_PLAYER_STATUS_RECOVER_FINISH, self.OnPlayerRecover)
end

function WorldCombatRecord:OnPlayerRecover()
  if not (self:IsSelfInWorldCombat() and self.baseInfo) or not self.baseInfo.BossActorID then
    return
  end
  local Player = _G.NRCModuleManager:DoCmd(_G.PlayerModuleCmd.GET_LOCAL_PLAYER)
  if Player then
    Player:SendEvent(PlayerModuleEvent.ON_PLAYER_PERCEPED_BY_NPC, self.baseInfo.BossActorID, true)
  end
end

function WorldCombatRecord:InternalFinishWorldCombat()
  if not self.baseInfo then
    return
  end
  self:TeardownAirWall(self.baseInfo.CombatConf)
  self:ResetBossSetting()
  _G.NRCEventCenter:DispatchEvent(WorldCombatModuleEvent.End, self.baseInfo.CombatID, self.baseInfo.BossActorID)
  _G.NRCModuleManager:DoCmd(PlayerModuleCmd.HIDE_NOVISIT_PLAYER, false, UE.EPlayerForceHiddenType.WorldCombat)
  local Player = _G.NRCModuleManager:DoCmd(_G.PlayerModuleCmd.GET_LOCAL_PLAYER)
  if Player then
    Player:SendEvent(PlayerModuleEvent.ON_PLAYER_LOST_PERCEPED_BY_NPC, self.baseInfo.BossActorID, true)
    Player:RemoveEventListener(self, PlayerModuleEvent.ON_PLAYER_PERCEPED_BY_NPC, self.OnPlayerRecover)
  end
  if not self.resetting then
    self:Reset()
  end
end

function WorldCombatRecord:InternalEnterWorldCombat()
  NRCModeManager:GetCurMode():ClosePanelByLayer(_G.Enum.UILayerType.UI_LAYER_FULLSCREEN)
  _G.NRCModuleManager:DoCmd(_G.FunctionBanModuleCmd.AddCondition, Enum.PlayerConditionType.PCT_WORLD_COMBATING)
  if self.baseInfo then
    local Boss = _G.NRCModuleManager:DoCmd(_G.NPCModuleCmd.GetNpcByServerID, self.baseInfo.BossActorID)
    _G.NRCEventCenter:DispatchEvent(MainUIModuleEvent.OnUpdateBossInfo, Boss)
    _G.NRCEventCenter:DispatchEvent(WorldCombatModuleEvent.Enter, self.baseInfo.CombatID, self.baseInfo.BossActorID, self.baseInfo.CombatConfID)
    _G.NRCModuleManager:DoCmd(PlayerModuleCmd.HIDE_NOVISIT_PLAYER, true, UE.EPlayerForceHiddenType.WorldCombat)
    local config = self.baseInfo.CombatConf
    if config and config.bgm_world_combat_state then
      local buff_component = Boss:GetComponent(WorldCombatBuffComponent)
      if buff_component and buff_component:HasBuffOfType(_G.Enum.WorldBuffEffect.WBE_BARRIER) then
        _G.NRCAudioManager:SetStateByName("Combat_Battle_Stage", "Shield_Stage")
      else
        _G.NRCAudioManager:SetStateByName("Combat_Battle_Stage", "Expose_Stage")
      end
      _G.NRCAudioManager:BatchSetState(string.format("World_Combat;World_Combat;%s", config.bgm_world_combat_state))
    end
    if not Boss:HasListener(self, NPCModuleEvent.OnAiControlFlagChanged, self.OnAiControlFlagChanged) then
      Boss:AddEventListener(self, NPCModuleEvent.OnAiControlFlagChanged, self.OnAiControlFlagChanged)
    end
    if not RocoEnv.IS_SHIPPING and Boss.viewObj then
      UE.URocoAIHelper.SelectToDebug(Boss.viewObj)
    end
  end
  if self.shieldInfo then
    if not self:IsShieldDataInited() then
      self:InitShieldDataFromNpc()
    end
    _G.NRCEventCenter:DispatchEvent(MainUIModuleEvent.OnBarrierShow, self.shieldInfo.shield_max_value, self.shieldInfo.shield_value)
    Log.Debug("[WorldCombatRecord:InternalEnterWorldCombat]Show", self.shieldInfo.shield_max_value)
    if self.shieldInfo.shield_state == _G.WorldCombatModuleEnum.ShieldState.Broken then
      Log.Debug("[WorldCombatRecord:InternalEnterWorldCombat]Broken", self.shieldInfo.shield_max_value)
      _G.NRCEventCenter:DispatchEvent(MainUIModuleEvent.OnBarrierBroken, self.shieldInfo.shield_max_value)
    elseif self.shieldInfo.shield_state == _G.WorldCombatModuleEnum.ShieldState.Hidden then
      Log.Debug("[WorldCombatRecord:InternalEnterWorldCombat]Hidden", self.shieldInfo.shield_max_value)
      _G.NRCEventCenter:DispatchEvent(MainUIModuleEvent.OnBarrierHidden, self.shieldInfo.shield_max_value)
    end
  end
  if self.baseInfo then
    local Boss = _G.NRCModuleManager:DoCmd(_G.NPCModuleCmd.GetNpcByServerID, self.baseInfo.BossActorID)
    local AIComp = Boss.AIComponent
    if AIComp and AIComp:HasControlFlags(_G.Enum.SceneAiControlFlags.SACF_PETBOSS_INVICIBLE) then
      _G.NRCEventCenter:DispatchEvent(MainUIModuleEvent.OnBarrierImmune)
    end
  end
end

function WorldCombatRecord:OnAiControlFlagChanged(newFlag, prevFlag, owner)
  if not self.baseInfo then
    return
  else
    local Boss = _G.NRCModuleManager:DoCmd(_G.NPCModuleCmd.GetNpcByServerID, self.baseInfo.BossActorID)
    if Boss ~= owner then
      return
    end
  end
  local changed = (newFlag ~ prevFlag) & 1 << Enum.SceneAiControlFlags.SACF_PETBOSS_INVICIBLE > 0
  if not changed then
    return
  end
  local bBarrierImmune = 0 ~= newFlag & 1 << Enum.SceneAiControlFlags.SACF_PETBOSS_INVICIBLE
  if bBarrierImmune then
    _G.NRCEventCenter:DispatchEvent(MainUIModuleEvent.OnBarrierImmune)
  else
    _G.NRCEventCenter:DispatchEvent(MainUIModuleEvent.OnBarrierExitImmune)
  end
end

function WorldCombatRecord:InternalExitWorldCombat()
  Log.Debug("WorldCombatRecord:InternalExitWorldCombat")
  _G.NRCModuleManager:DoCmd(_G.FunctionBanModuleCmd.RemoveCondition, Enum.PlayerConditionType.PCT_WORLD_COMBATING)
  if self:IsSelfInWorldCombat() then
    _G.NRCEventCenter:DispatchEvent(MainUIModuleEvent.OnBarrierHidden)
  end
  if self.baseInfo then
    _G.NRCEventCenter:DispatchEvent(WorldCombatModuleEvent.Exit, self.baseInfo.CombatID, self.baseInfo.BossActorID, self.baseInfo.CombatConfID)
    local Boss = _G.NRCModuleManager:DoCmd(_G.NPCModuleCmd.GetNpcByServerID, self.baseInfo.BossActorID)
    Boss:RemoveEventListener(self, NPCModuleEvent.OnAiControlFlagChanged, self.OnAiControlFlagChanged)
  end
  _G.NRCAudioManager:BatchSetState("World_Combat;None")
end

function WorldCombatRecord:SetupAirWall(Conf, bNightmare)
  if Conf then
    _G.NRCModuleManager:DoCmd(_G.AirWallModuleCmd.CreateWall, Conf.block_id)
  end
  if _G.NRCModuleManager:DoCmd(_G.WorldCombatModuleCmd.GetCanDrawDebug) then
    if self.regionInfo.debugBlock then
      self.regionInfo.debugBlock:K2_DestroyActor()
      self.regionInfo.debugBlock = nil
    end
    self.regionInfo.debugBlock = _G.NRCModuleManager:DoCmd(_G.AirWallModuleCmd.CreateDebugBlock, Conf.block_id, string.format("WorldCombat_%d_%s", Conf.id, Conf.editor_name), nil, 500)
  end
end

function WorldCombatRecord:TeardownAirWall(Conf)
  if Conf then
    _G.NRCModuleManager:DoCmd(_G.AirWallModuleCmd.DestroyWall, Conf.block_id)
  end
  if self.regionInfo.debugBlock then
    self.regionInfo.debugBlock:K2_DestroyActor()
    self.regionInfo.debugBlock = nil
  end
end

function WorldCombatRecord:InitBossSetting(npc_id, world_combat_phase)
  local boss = _G.NRCModuleManager:DoCmd(_G.NPCModuleCmd.GetNpcByServerID, npc_id)
  if not boss then
    return
  end
  _G.NRCModuleManager:DoCmd(_G.SceneModuleCmd.ConsumeCachedActorTag, npc_id)
  boss:SetSignificant(false, UE.ESignificanceValue.Highest)
  self:RegisterSpecialPet(boss)
  local AIComp = boss.AIComponent
  if AIComp then
    AIComp:OnWorldCombatPhaseUpdated(world_combat_phase)
  end
  local bossViewObj = boss:GetViewObject()
  if bossViewObj then
    self:CompleteBossInitialization(boss)
  else
    boss:AddEventListener(self, NPCModuleEvent.VIEW_SHELL_LOADED, self.OnBossViewLoaded)
  end
  if not boss:HasListener(self, NPCModuleEvent.On_NPC_LEAVE, self.OnBossLeave) then
    boss:AddEventListener(self, NPCModuleEvent.On_NPC_LEAVE, self.OnBossLeave)
  end
  if not boss:HasListener(self, MainUIModuleEvent.OnBarrierShow, self.OnBarrierShow) then
    boss:AddEventListener(self, MainUIModuleEvent.OnBarrierShow, self.OnBarrierShow)
  end
  if not boss:HasListener(self, MainUIModuleEvent.OnBarrierChange, self.OnBarrierChange) then
    boss:AddEventListener(self, MainUIModuleEvent.OnBarrierChange, self.OnBarrierChange)
  end
  if not boss:HasListener(self, MainUIModuleEvent.OnBarrierBroken, self.OnBarrierBroken) then
    boss:AddEventListener(self, MainUIModuleEvent.OnBarrierBroken, self.OnBarrierBroken)
  end
end

local LocalSpawnTransformObj = UE.FTransform()
local LocalTargetClass = UE.ANPCSimpleSkillTarget

function WorldCombatRecord:ResetBossSetting()
  if not self.baseInfo then
    return
  end
  local boss = _G.NRCModuleManager:DoCmd(_G.NPCModuleCmd.GetNpcByServerID, self.baseInfo.BossActorID)
  if boss then
    boss:SetSignificant(true)
    self:UnRegisterSpecialPet()
    local bossViewObj = boss:GetViewObject()
    if bossViewObj and bossViewObj.Mesh then
      bossViewObj.Mesh:SetForcedLOD(0)
    end
    boss:Stop()
    boss:EnsureComponent(WorldCombatSkillComponent):ForceStopCurrentSkill()
    boss:SetCollisionDisable(false, NPCModuleEnum.NpcReasonFlags.AI)
    boss:SetCollisionDisable(false, NPCModuleEnum.NpcReasonFlags.WORLD_COMBAT_HIDDEN)
    local isBattle = _G.NRCModuleManager:DoCmd(BattleModuleCmd.IsInBattle)
    if isBattle then
      _G.NRCEventCenter:RegisterEvent(self.name or "WorldCombatRecord", self, BattleEvent.LeaveBattle, self.ResetBossShow)
    else
      self:ResetBossShow()
    end
    local bossBronPoint = boss.serverData.base.born_pt
    local teleportSkillId = self.baseInfo.CombatConf.teleport_skill
    local skillConf = _G.DataConfigManager:GetWorldCombatSkillConf(teleportSkillId, true)
    local teleportSkill = ""
    if skillConf and skillConf.skill_ref then
      teleportSkill = skillConf.skill_ref
    end
    if string.IsNilOrEmpty(teleportSkill) or boss.isDestroy then
      Log.PrintScreenMsg("[WorldCombatRecord:ResetBossSetting] Skip Reset Pos, moving back")
      if UE.UObject.IsValid(bossViewObj) then
        bossViewObj:ForceLockOnGround()
      end
    else
      Log.PrintScreenMsg("[WorldCombatRecord:ResetBossSetting] Playing teleport skill")
      local skillProxy = RocoSkillProxy.Create(teleportSkill, bossViewObj.RocoSkill, 5)
      if skillProxy then
        skillProxy:SetCaster(bossViewObj)
        
        local function SetupSkillTarget(this, Name, skillObj)
          LocalSpawnTransformObj.Translation = bossBronPoint
          local TargetObj = skillObj:GetWorld():Abs_SpawnActor(LocalTargetClass, LocalSpawnTransformObj, UE4.ESpawnActorCollisionHandlingMethod.AlwaysSpawn)
          skillObj:SetTargets({TargetObj})
          skillObj:GetBlackboard():SetValueAsObject("TargetObj", TargetObj)
        end
        
        skillProxy:RegisterEventCallback("PreStart", self, SetupSkillTarget)
        skillProxy:RegisterEventCallback("OnTeleport", self, self.OnResetTeleport)
        skillProxy:RegisterEventCallback("ActivateFailed", self, self.OnResetTeleportSkillEnd)
        skillProxy:RegisterEventCallback("End", self, self.OnResetTeleportSkillEnd)
        skillProxy:RegisterEventCallback("PreEnd", self, self.OnResetTeleportSkillEnd)
        skillProxy:RegisterEventCallback("Interrupt", self, self.OnResetTeleportSkillEnd)
        skillProxy:PlaySkill()
        self.teleportSkillProxy = skillProxy
        self.resetting = true
      else
        Log.PrintScreenMsg("[WorldCombatRecord:ResetBossSetting] Cant playing teleport skill, path: %s", teleportSkill)
      end
    end
    boss:ReportPosition()
  else
    Log.Debug("WorldCombatRecord:ResetBossSetting, Can't find boss")
  end
  self:RemoveBossListener(boss)
end

function WorldCombatRecord:ResetBossShow()
  _G.NRCEventCenter:UnRegisterEvent(self, BattleEvent.LeaveBattle, self.ResetBossShow)
  local boss = _G.NRCModuleManager:DoCmd(_G.NPCModuleCmd.GetNpcByServerID, self.baseInfo.BossActorID)
  if not boss then
    return
  end
  local bossViewObj = boss:GetViewObject()
  if not UE.UObject.IsValid(bossViewObj) then
    return
  end
  boss.hiddenFlag = 0
  boss:SetVisibleInternal(true)
  local meshComp = SceneUtils.GetActorMesh(bossViewObj)
  if meshComp then
    meshComp:SetVisibility(true, false)
    local HiddenComponent = boss.HiddenComponent
    if not HiddenComponent or not HiddenComponent:IsHidden() then
      meshComp:SetHiddenInGame(false, false)
    end
  end
end

function WorldCombatRecord:OnBossViewLoaded(boss)
  if not boss then
    return
  end
  boss:RemoveEventListener(self, NPCModuleEvent.VIEW_SHELL_LOADED, self.OnBossViewLoaded)
  self:CompleteBossInitialization(boss)
end

function WorldCombatRecord:CompleteBossInitialization(boss)
  if not boss then
    return
  end
  local BossViewObj = boss.viewObj
  if BossViewObj.Mesh then
    BossViewObj.Mesh:SetForcedLOD(1)
  end
  boss:EnsureComponent(OverlapAwareVisibilityComponent):CheckInBoundAndMarkHidden(true, true, false, -5, true)
end

function WorldCombatRecord:OnBossLeave(boss)
  if not boss then
    return
  end
  Log.Debug("WorldCombatRecord:OnBossLeave", self:GetDebugInfo())
  local Action = _G.ProtoMessage:newSpaceAct_WorldCombatFinish()
  Action.npc_id = boss:GetServerId()
  _G.NRCModuleManager:DoCmd(_G.WorldCombatModuleCmd.WorldCombatFinish, Action)
end

function WorldCombatRecord:RemoveBossListener(boss)
  if boss then
    boss:RemoveEventListener(self, NPCModuleEvent.On_NPC_LEAVE, self.OnBossLeave)
    boss:RemoveEventListener(self, MainUIModuleEvent.OnBarrierShow, self.OnBarrierShow)
    boss:RemoveEventListener(self, MainUIModuleEvent.OnBarrierChange, self.OnBarrierChange)
    boss:RemoveEventListener(self, MainUIModuleEvent.OnBarrierBroken, self.OnBarrierBroken)
  end
end

function WorldCombatRecord:OnResetTeleport()
  if not self.teleportSkillProxy then
    return
  end
  if self.teleportSkillProxy.__isteleported then
    return
  end
  self.teleportSkillProxy.__isteleported = true
  local boss = _G.NRCModuleManager:DoCmd(_G.NPCModuleCmd.GetNpcByServerID, self.baseInfo.BossActorID)
  if boss and not boss.isDestroy then
    local bossBronPoint = boss.serverData.base.born_pt
    local bossViewObj = boss:GetViewObject()
    if bossViewObj and bossBronPoint then
      local position, rotation = SceneUtils.SplitPoint(bossBronPoint)
      position.Z = position.Z + bossViewObj:GetHalfHeight()
      boss:SetActorLocation(position)
      boss:SetActorRotation(rotation)
      boss.serverPos = position
      bossViewObj:FixCoord(true)
      boss:ReportPosition()
    end
  end
end

function WorldCombatRecord:OnResetTeleportSkillEnd()
  self:OnResetTeleport()
  self.teleportSkillProxy = nil
  if self.resetting then
    self.resetting = false
    self:Reset()
  end
end

function WorldCombatRecord:OnBossReconnect(npc, ServerData, isReconnect)
  if npc then
    Log.Debug("WorldCombatRecord:OnBossReconnect", npc:DebugNPCNameAndID(), isReconnect)
  end
  if isReconnect then
    local bInBattle = _G.NRCModuleManager:DoCmd(_G.WorldCombatModuleCmd.GetInBattle)
    self:SetAirWallVisible(not bInBattle)
    if self:IsSelfInWorldCombat() then
      _G.NRCEventCenter:DispatchEvent(MainUIModuleEvent.OnUpdateBossInfo, npc)
      _G.NRCModuleManager:DoCmd(_G.MainUIModuleCmd.TryDisplayAdditionalTarget)
      if npc then
        if ServerData.world_combat_skill_info.show_hide_info then
          Log.Debug("WorldCombatRecord:OnBossReconnect with show hide info", npc:DebugNPCNameAndID(), isReconnect, ServerData.world_combat_skill_info.show_hide_info.show_state)
          local WorldCombatActionFactory = require("NewRoco.Modules.Core.NPC.Actions.WorldCombatActions.WorldCombatActionFactory")
          local caster = _G.NRCModuleManager:DoCmd(_G.NPCModuleCmd.GetNpcByServerID, ServerData.base.actor_id)
          local info = _G.ProtoMessage:newSnapshoot_WorldCombatSkillActionShowHide()
          info.show_hide_info = ServerData.world_combat_skill_info.show_hide_info
          local actionData = _G.ProtoMessage:newActorInfo_WorldCombatSkillAction()
          actionData.show_hide_snapshoot = info
          actionData.skill_action_type = _G.ProtoEnum.SkillActionType.WorldCombatDotsSkillShowHide
          WorldCombatActionFactory:DispatchActionOnReconnect(caster, ServerData.world_combat_skill_info.skill_id, actionData)
        end
        local worldCombatSkillComponent = npc.WorldCombatSkillComponent
        if worldCombatSkillComponent then
          worldCombatSkillComponent:CurrSkillPerformOnReconnect(ServerData)
        end
        npc:EnsureComponent(OverlapAwareVisibilityComponent):CheckInBoundAndMarkHidden(true, true, false, -5, true)
      end
    end
  end
end

function WorldCombatRecord:OnBarrierChange(old_value, new_value, isCrit)
  self.shieldInfo.shield_value = new_value
  self.shieldInfo.shield_state = _G.WorldCombatModuleEnum.ShieldState.Normal
  if self.shieldInfo.shield_value <= 0 then
    self.shieldInfo.shield_state = _G.WorldCombatModuleEnum.ShieldState.Broken
  end
  Log.Debug("WorldCombatRecord:OnBarrierChange", self:GetDebugInfo(), old_value, new_value, isCrit)
  if self:IsSelfInWorldCombat() and self.shieldInfo.shield_value and self.shieldInfo.shield_value then
    _G.NRCEventCenter:DispatchEvent(MainUIModuleEvent.OnBarrierChange, old_value, new_value, isCrit)
  end
end

function WorldCombatRecord:OnBarrierShow(max_value, new_value)
  if not self:IsShieldDataInited() then
    self:InitShieldDataFromNpc()
  end
  self.shieldInfo.shield_max_value = max_value
  self.shieldInfo.shield_value = new_value
  self.shieldInfo.shield_state = _G.WorldCombatModuleEnum.ShieldState.Normal
  if self.shieldInfo.shield_value <= 0 then
    self.shieldInfo.shield_state = _G.WorldCombatModuleEnum.ShieldState.Hidden
  end
  Log.Debug("WorldCombatRecord:OnBarrierShow", self:GetDebugInfo(), max_value, new_value)
  if self:IsSelfInWorldCombat() then
    local Boss = _G.NRCModuleManager:DoCmd(_G.NPCModuleCmd.GetNpcByServerID, self.baseInfo.BossActorID)
    _G.NRCEventCenter:DispatchEvent(MainUIModuleEvent.OnUpdateBossInfo, Boss)
    _G.NRCEventCenter:DispatchEvent(MainUIModuleEvent.OnBarrierShow, max_value, new_value)
  end
end

function WorldCombatRecord:OnBarrierBroken(max_value)
  self.shieldInfo.shield_max_value = max_value
  self.shieldInfo.shield_value = 0
  self.shieldInfo.shield_state = _G.WorldCombatModuleEnum.ShieldState.Broken
  Log.Debug("WorldCombatRecord:OnBarrierBroken", self:GetDebugInfo(), max_value)
  if self:IsSelfInWorldCombat() then
    _G.NRCEventCenter:DispatchEvent(MainUIModuleEvent.OnBarrierBroken, max_value)
  end
end

function WorldCombatRecord:IsShieldDataInited()
  if self.shieldInfo.shield_value and self.shieldInfo.shield_max_value then
    return true
  end
  return false
end

function WorldCombatRecord:InitShieldDataFromNpc()
  if not self.baseInfo then
    return
  end
  local Boss = _G.NRCModuleManager:DoCmd(_G.NPCModuleCmd.GetNpcByServerID, self.baseInfo.BossActorID)
  if not Boss then
    self.shieldInfo.shield_value = 0
    self.shieldInfo.shield_max_value = 0
    Log.Debug("WorldCombatRecord:InitShieldDataFromNpc not found boss", self:GetDebugInfo())
    return
  end
  local WorldCombatBuffComp = Boss:EnsureComponent(WorldCombatBuffComponent)
  if WorldCombatBuffComp and WorldCombatBuffComp.Buffs then
    for _, Buff in pairs(WorldCombatBuffComp.Buffs) do
      local cfg_id = Buff.Info.buff_cfg_id
      local Conf = _G.DataConfigManager:GetWorldBuffConf(cfg_id)
      if Conf and Conf.buff_effect_type == Enum.WorldBuffEffect.WBE_BARRIER then
        self.shieldInfo.shield_value = Buff.Info.buff_val
        self.shieldInfo.shield_state = _G.WorldCombatModuleEnum.ShieldState.Broken
        if self.shieldInfo.shield_value > 0 then
          self.shieldInfo.shield_state = _G.WorldCombatModuleEnum.ShieldState.Normal
        end
        self.shieldInfo.shield_max_value = self.shieldInfo.shield_value
        if Buff.Info.int_params_list and #Buff.Info.int_params_list > 0 then
          self.shieldInfo.shield_max_value = Buff.Info.int_params_list[1]
        end
        Log.Debug("WorldCombatRecord:InitShieldDataFromNpc found barrier buff", self:GetDebugInfo(), self.shieldInfo.shield_max_value, self.shieldInfo.shield_value, self.shieldInfo.shield_state)
        return
      end
    end
  end
  self.shieldInfo.shield_value = 0
  self.shieldInfo.shield_max_value = 0
  Log.Debug("WorldCombatRecord:InitShieldDataFromNpc not found barrier buff", self:GetDebugInfo())
end

function WorldCombatRecord:ShouldDoRegionCheck()
  if not self.regionInfo then
    return false
  end
  if not self.regionInfo.SplinePoint2D then
    return false
  end
  if self.regionInfo.SplinePoint2D:Length() < 1 then
    Log.Debug("WorldCombatModule:OnTick: InValid Spline", self.SplinePoint2D:Length())
    return false
  end
  return true
end

function WorldCombatRecord:IsPointInRegion(InPos)
  if not self.regionInfo then
    return false
  end
  if not self.regionInfo.SplinePoint2D then
    return false
  end
  return UE.UNewRocoHelperLibrary.PointInPolygon(InPos, self.regionInfo.SplinePoint2D)
end

function WorldCombatRecord:RegisterSpecialPet(Boss)
  if not self.SpecialToken then
    self.SpecialToken = _G.NRCAudioManager:StartRegisterSpecialPet()
  end
  if Boss and UE.UObject.IsValid(Boss.viewObj) then
    _G.NRCAudioManager:RegisterSpecialPet(self.SpecialToken, Boss.viewObj)
  end
end

function WorldCombatRecord:UnRegisterSpecialPet()
  if self.SpecialToken then
    _G.NRCAudioManager:EndRegisterSpecialPet(self.SpecialToken)
    self.SpecialToken = nil
  end
end

function WorldCombatRecord:GetAirWallID()
  if self:IsSelfInWorldCombat() and self.baseInfo.CombatConf then
    return self.baseInfo.CombatConf.block_id
  end
end

function WorldCombatRecord:SetAirWallVisible(bVisible)
  if not self.baseInfo then
    return
  end
  local conf = self.baseInfo.CombatConf
  if conf then
    local blockId = conf.block_id
    local airWall = _G.NRCModuleManager:DoCmd(_G.AirWallModuleCmd.GetWall, blockId)
    if airWall and UE.UObject.IsValid(airWall) then
      airWall:SetActorHiddenInGame(not bVisible)
      airWall:SetActorEnableCollision(bVisible)
    else
      Log.Warning("WorldCombatRecord:SetAirWallVisible not found air wall", self:GetDebugInfo(), blockId, bVisible)
    end
  end
end

return WorldCombatRecord

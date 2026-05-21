local TipObject = require("NewRoco.Modules.System.TipsModule.Utils.TipObject")
local SceneEvent = require("NewRoco.Modules.Core.Scene.Common.SceneEvent")
local DialogContext = require("NewRoco.Modules.System.TipsModule.DialogContext")
local WorldCombatStatus = require("NewRoco.Modules.System.WorldCombat.WorldCombatStatus")
local SceneUtils = require("NewRoco.Modules.Core.Scene.Common.SceneUtils")
local WorldCombatSkillComponent = require("NewRoco.Modules.Core.Scene.Component.WorldCombat.WorldCombatSkillComponent")
local TipEnum = require("NewRoco.Modules.System.TipsModule.Utils.TipEnum")
local MainUIModuleEvent = require("NewRoco.Modules.System.MainUI.MainUIModuleEvent")
local WorldCombatActionFactory = require("NewRoco.Modules.Core.NPC.Actions.WorldCombatActions.WorldCombatActionFactory")
local WorldCombatModuleEnum = require("NewRoco.Modules.System.WorldCombat.WorldCombatModuleEnum")
local CinematicModuleEvent = require("NewRoco.Modules.Core.Cinematic.CinematicModuleEvent")
local PlayerModuleEvent = require("NewRoco.Modules.Core.PlayerModule.PlayerModuleEvent")
local OverlapAwareVisibilityComponent = require("NewRoco.Modules.Core.Scene.Component.Visibility.OverlapAwareVisibilityComponent")
local NPCModuleEvent = require("NewRoco.Modules.Core.NPC.NPCModuleEvent")
local FriendModuleEvent = require("NewRoco.Modules.System.Friend.FriendModuleEvent")
local LoadingUIModuleEvent = require("NewRoco.Modules.System.LoadingUIModule.LoadingUIModuleEvent")
local WorldCombatRecord = require("NewRoco.Modules.System.WorldCombat.WorldCombatRecord")
local WorldCombatBossInfo = require("NewRoco.Modules.System.WorldCombat.WorldCombatBossInfo")
local MiniGameModuleEvent = require("NewRoco.Modules.System.MiniGame.MiniGameModuleEvent")
local PosDiffLerpThreshold = 10
local DirDiffLerpThreshold = 5
local BossPosDirLerpAction = _G.MakeSimpleClass("BossPosDirLerpAction")

function BossPosDirLerpAction:Ctor(runner, targetPos, targetDir, duration, posThreshold, dirThreshold, callBack, ...)
  self.runner = runner
  self.targetPos = targetPos
  self.targetDir = targetDir
  self.duration = duration
  self.posThreshold = posThreshold or PosDiffLerpThreshold
  self.dirThreshold = dirThreshold or DirDiffLerpThreshold
  self.callBack = callBack
  self.params = {
    ...
  }
  self.currTime = UE4.UNRCStatics.GetTimestampMS()
  self.expireTime = self.currTime + self.duration
end

local WorldCombatModule = NRCModuleBase:Extend("WorldCombatModule")
local MaxLeaveCombatDist = 2000
local MaxLeaveCombatDistSqr = MaxLeaveCombatDist * MaxLeaveCombatDist
local LeavingTime = 10
local DefaultCurrentBossNpcId = -1
local DefaultCurrentRewardNpcId = -1
local EnterWorldCombatBanLogicStatus = {
  Enum.SpaceActorLogicStatus.SALE_REVIVE,
  Enum.SpaceActorLogicStatus.SALS_CHANGE_EGG,
  Enum.SpaceActorLogicStatus.SALS_FIGHTING,
  Enum.SpaceActorLogicStatus.SALS_INTERACTING
}

function WorldCombatModule:OnConstruct()
  _G.WorldCombatModuleCmd = reload("NewRoco.Modules.System.WorldCombat.WorldCombatModuleCmd")
  _G.WorldCombatModuleEnum = reload("NewRoco.Modules.System.WorldCombat.WorldCombatModuleEnum")
  _G.WorldCombatModuleEvent = reload("NewRoco.Modules.System.WorldCombat.WorldCombatModuleEvent")
  self.data = self:SetData("WorldCombatModuleData", "NewRoco.Modules.System.WorldCombat.WorldCombatModuleData")
  self:ResetParameter()
  self.isVisitor = false
  self.bDrawDebugFlag = false
  self.bShowAIServerError = false
  self.cachedServerTips = nil
  self.currSkillActions = {}
  self.bEditorPerformanceImprovement = false
  self.hideNpcViews = {}
end

function WorldCombatModule:OnActive()
  _G.NRCEventCenter:RegisterEvent(self.name, self, _G.WorldCombatModuleEvent.OnExitButtonClicked, self.OnExitButtonClicked)
  _G.NRCEventCenter:RegisterEvent(self.name, self, SceneEvent.LoadMapStart, self.LoadMapStart)
  _G.NRCEventCenter:RegisterEvent(self.name, self, SceneEvent.LoadMapFinish, self.LoadMapFinish)
  _G.NRCEventCenter:RegisterEvent(self.name, self, _G.NRCGlobalEvent.ON_RECONNECT_FINISH, self.OnReconnect)
  _G.NRCEventCenter:RegisterEvent(self.name, self, _G.WorldCombatModuleEvent.OnBattleRealEnd, self.OnBattleRealEnd)
  _G.NRCEventCenter:RegisterEvent(self.name, self, FriendModuleEvent.OnEnterVisit, self.OnEnterVisit)
  _G.NRCEventCenter:RegisterEvent(self.name, self, FriendModuleEvent.OnLeaveVisit, self.OnLeaveVisit)
  _G.NRCEventCenter:RegisterEvent(self.name, self, LoadingUIModuleEvent.LOADING_UI_CLOSED, self.OnLoadingClosed)
  _G.NRCEventCenter:RegisterEvent(self.name, self, _G.WorldCombatModuleEvent.BossReconnect, self.OnBossReconnect)
  _G.NRCEventCenter:RegisterEvent(self.name, self, _G.WorldCombatModuleEvent.BossInited, self.OnBossInited)
  _G.NRCEventCenter:RegisterEvent(self.name, self, MiniGameModuleEvent.OnMiniGameExit, self.OnMiniGameExit)
  _G.NRCEventCenter:RegisterEvent(self.name, self, _G.NRCGlobalEvent.OnApplicationHasEnteredForeground, self.OnEnterForeground)
  _G.NRCEventCenter:RegisterEvent(self.name, self, _G.NRCGlobalEvent.OnApplicationWillEnterBackground, self.OnEnterBackground)
  _G.UpdateManager:UnRegister(self)
  self.DelayCheckDelegate = nil
end

function WorldCombatModule:OnEnterForeground()
  Log.Debug("[WorldCombatModule:OnEnterForeground]")
  if not self:OnIsSelfInWorldCombat() then
    Log.Debug("WorldCombatModule:OnEnterForeground: Close World_Combat BGM")
    _G.NRCAudioManager:BatchSetState("World_Combat;None")
  end
end

function WorldCombatModule:OnEnterBackground()
  Log.Debug("[WorldCombatModule:OnEnterBackground]")
end

function WorldCombatModule:OnDeactive()
  _G.NRCEventCenter:UnRegisterEvent(self, _G.WorldCombatModuleEvent.OnExitButtonClicked, self.OnExitButtonClicked)
  _G.NRCEventCenter:UnRegisterEvent(self, SceneEvent.LoadMapStart, self.LoadMapStart)
  _G.NRCEventCenter:UnRegisterEvent(self, SceneEvent.LoadMapFinish, self.LoadMapFinish)
  _G.NRCEventCenter:UnRegisterEvent(self, _G.NRCGlobalEvent.ON_RECONNECT_FINISH, self.OnReconnect)
  _G.NRCEventCenter:UnRegisterEvent(self, _G.WorldCombatModuleEvent.OnBattleRealEnd, self.OnBattleRealEnd)
  _G.NRCEventCenter:UnRegisterEvent(self, FriendModuleEvent.OnEnterVisit, self.OnEnterVisit)
  _G.NRCEventCenter:UnRegisterEvent(self, FriendModuleEvent.OnLeaveVisit, self.OnLeaveVisit)
  _G.NRCEventCenter:UnRegisterEvent(self, LoadingUIModuleEvent.LOADING_UI_CLOSED, self.OnLoadingClosed)
  _G.NRCEventCenter:UnRegisterEvent(self, _G.WorldCombatModuleEvent.BossReconnect, self.OnBossReconnect)
  _G.NRCEventCenter:UnRegisterEvent(self, _G.WorldCombatModuleEvent.BossInited, self.OnBossInited)
  _G.NRCEventCenter:UnRegisterEvent(self, MiniGameModuleEvent.OnMiniGameExit, self.OnMiniGameExit)
  _G.NRCEventCenter:UnRegisterEvent(self, _G.NRCGlobalEvent.OnApplicationHasEnteredForeground, self.OnEnterForeground)
  _G.NRCEventCenter:UnRegisterEvent(self, _G.NRCGlobalEvent.OnApplicationWillEnterBackground, self.OnEnterBackground)
  if self.DelayCheckDelegate then
    _G.DelayManager:CancelDelayById(self.DelayCheckDelegate)
    self.DelayCheckDelegate = nil
  end
end

function WorldCombatModule:CheckCanEnterWorldCombat()
  local LocalPlayer = _G.NRCModuleManager:DoCmd(_G.PlayerModuleCmd.GET_LOCAL_PLAYER)
  if not LocalPlayer then
    return false
  end
  for _, status in pairs(EnterWorldCombatBanLogicStatus) do
    local isInStatus, _, _ = LocalPlayer.LogicStatusComponent:GetStatus(status)
    if isInStatus then
      return false
    end
  end
  return true
end

function WorldCombatModule:OnTick(DeltaTime)
  if self.Status == WorldCombatStatus.None then
    Log.Debug("WorldCombatModule:OnTick: status is None", self.Status, table.getKeyName(WorldCombatStatus, self.Status))
    self:ClearWaitLerpActions()
    return
  end
  if self.bInBattle then
    Log.Debug("WorldCombatModule:OnTick: Now in Battle", self.bInBattle)
    self:ClearWaitLerpActions()
    return
  end
  local LocalPlayer = _G.NRCModuleManager:DoCmd(_G.PlayerModuleCmd.GET_LOCAL_PLAYER)
  if not LocalPlayer then
    Log.Debug("WorldCombatModule:OnTick: No LocalPlayer")
    self:ClearWaitLerpActions()
    return
  end
  if self.JustReconnected and not LocalPlayer:IsLogicStatus(ProtoEnum.SpaceActorLogicStatus.SALS_WORLD_COMBAT) then
    Log.Debug("WorldCombatModule:OnTick, JustReconnected and not SALS_WORLD_COMBAT")
    self:ExitWorldCombatOnReconnect()
    self:ClearWaitLerpActions()
    return
  end
  if LocalPlayer:IsLogicStatus(ProtoEnum.SpaceActorLogicStatus.SALS_WORLD_COMBAT_LEAVING) and self.LeavingTimer > 0 then
    self.LeavingTimer = self.LeavingTimer + DeltaTime
  end
  local actionsToRemove = {}
  for _, action in ipairs(self.WaitLerpActions) do
    action.currTime = UE4.UNRCStatics.GetTimestampMS()
    local leftTime = _G.math.max(action.expireTime - action.currTime, 0)
    if leftTime <= 0 then
      action.runner:SetActorLocation(action.targetPos)
      if not table.contains(actionsToRemove, action) then
        table.insert(actionsToRemove, action)
      end
    else
      local param = _G.math.min(_G.math.max(1 - leftTime / action.duration, 0), 1)
      local posLerpDone = false
      local dirLerpDone = false
      if self:CheckBossPosNeedLerp(action.runner, action.targetPos, action.posThreshold) then
        Log.Debug("WorldCombatModule: OnTick: param", leftTime, action.duration, param, action.runner:GetActorLocation(), action.targetPos, (action.targetPos - action.runner:GetActorLocation()):Size())
        local nextLocation = _G.LuaMathUtils.LerpVector(action.runner:GetActorLocation(), action.targetPos, param)
        action.runner:SetActorLocation(nextLocation)
      else
        posLerpDone = true
        action.runner:SetActorLocation(action.targetPos)
      end
      if self:CheckBossDirNeedLerp(action.runner, action.targetDir, action.dirThreshold) then
        local nextDir = _G.LuaMathUtils.Slerp(action.runner:GetForwardVector(), action.targetDir, param)
        action.runner:SetActorRotation(nextDir:ToRotator())
      else
        dirLerpDone = true
        action.runner:SetActorRotation(action.targetDir:ToRotator())
      end
      if posLerpDone and dirLerpDone and not table.contains(actionsToRemove, action) then
        table.insert(actionsToRemove, action)
      end
    end
  end
  for _, action in ipairs(actionsToRemove) do
    if type(action.callBack) == "function" then
      action.callBack(table.unpack(action.params))
    end
    table.removeValue(self.WaitLerpActions, action)
  end
  if self.TickTimer > self.TickInterval then
    self.TickTimer = 0
  else
    self.TickTimer = self.TickTimer + DeltaTime
    return
  end
  local canEnter = self:CheckCanEnterWorldCombat()
  local CurPlayerPos = LocalPlayer:GetActorLocation()
  local CurPlayerPos2D = UE.FVector2D(CurPlayerPos.X, CurPlayerPos.Y)
  if self:OnGetWorldCombatStatus() == WorldCombatStatus.Playing then
    if canEnter and not LocalPlayer:IsLogicStatus(ProtoEnum.SpaceActorLogicStatus.SALS_WORLD_COMBAT) then
      for _, record in pairs(self.records) do
        if not record:IsSelfInWorldCombat() and record:ShouldDoRegionCheck() and record:IsPointInRegion(CurPlayerPos2D) then
          local WorldCombatEnterReq = _G.ProtoMessage:newZoneSceneWorldCombatEnterReq()
          WorldCombatEnterReq.npc_id = record.baseInfo.BossActorID
          _G.ZoneServer:SendWithHandler(_G.ProtoCMD.ZoneSvrCmd.ZONE_SCENE_WORLD_COMBAT_ENTER_REQ, WorldCombatEnterReq, self, self.OnEnterWorldCombatRsp, false, true)
          Log.Debug("WorldCombatModule: Player Enter Existed WorldCombat", LocalPlayer.serverData.base.actor_id, record:GetDebugInfo())
          break
        end
      end
    end
  elseif self:OnGetWorldCombatStatus() == WorldCombatStatus.Enter then
    local record = self:GetCurrentCombatRecord()
    if record then
      local bossId = record.baseInfo.BossActorID
      if record:IsPointInRegion(CurPlayerPos2D) then
        if LocalPlayer:IsLogicStatus(ProtoEnum.SpaceActorLogicStatus.SALS_WORLD_COMBAT_LEAVING) then
          local WorldCombatEnterReq = _G.ProtoMessage:newZoneSceneWorldCombatEnterReq()
          WorldCombatEnterReq.npc_id = bossId
          _G.ZoneServer:SendWithHandler(ProtoCMD.ZoneSvrCmd.ZONE_SCENE_RE_ENTER_WORLD_COMBAT_AREA_REQ, WorldCombatEnterReq, self, self.OnEnterWorldCombatRsp, false, true)
          Log.Debug("WorldCombatModule: Player ReEnter Existed WorldCombat", LocalPlayer.serverData.base.actor_id, record:GetDebugInfo())
        end
      elseif LocalPlayer:IsLogicStatus(ProtoEnum.SpaceActorLogicStatus.SALS_WORLD_COMBAT_LEAVING) then
        local DistSqr = UE.UNRCStatics.ClosestPointDistSqrToPolygon2D(CurPlayerPos2D, record.regionInfo.SplinePoint2D)
        if not record.regionInfo.SplinePoint2D or DistSqr <= -1 then
          Log.Debug("WorldCombatModule: No Valid SplinePoint2D!", LocalPlayer.serverData.base.actor_id, record:GetDebugInfo())
        end
        if DistSqr > MaxLeaveCombatDistSqr then
          local ExitWorldCombatReq = _G.ProtoMessage:newZoneSceneWorldCombatExitReq()
          ExitWorldCombatReq.npc_id = bossId
          _G.ZoneServer:SendWithHandler(ProtoCMD.ZoneSvrCmd.ZONE_SCENE_WORLD_COMBAT_EXIT_REQ, ExitWorldCombatReq, self, self.OnExitRsp, false, true)
          Log.Debug("WorldCombatModule: Player Exit WorldCombat", LocalPlayer.serverData.base.actor_id, record:GetDebugInfo())
        end
      elseif LocalPlayer:IsLogicStatus(ProtoEnum.SpaceActorLogicStatus.SALS_WORLD_COMBAT) then
        local LeaveWorldCombatAreaReq = _G.ProtoMessage:newZoneSceneLeaveWorldCombatAreaReq()
        LeaveWorldCombatAreaReq.npc_id = bossId
        _G.ZoneServer:SendWithHandler(ProtoCMD.ZoneSvrCmd.ZONE_SCENE_LEAVE_WORLD_COMBAT_AREA_REQ, LeaveWorldCombatAreaReq, self, self.OnLeaveAreaRsp, false, true)
        Log.Debug("WorldCombatModule: Player Leave WorldCombat", LocalPlayer.serverData.base.actor_id, record:GetDebugInfo())
      end
    end
  end
end

function WorldCombatModule:ResetParameter()
  self.ExitContext = nil
  self.localPlayerBossId = DefaultCurrentBossNpcId
  self.currentRewardNpcId = DefaultCurrentRewardNpcId
  self.records = {}
  self.rewards = {}
  self.bInBattle = false
  self.TickTimer = 0
  self.TickInterval = 0.5
  self.LeavingTimer = -1
  self.JustReconnected = nil
  self.WaitLerpActions = {}
end

function WorldCombatModule:GetCurrentCombatRecord()
  if self.localPlayerBossId == DefaultCurrentBossNpcId then
    return nil
  end
  if self.records then
    return self.records[self.localPlayerBossId]
  end
  return nil
end

function WorldCombatModule:OnGetWorldCombatStatus()
  if self:OnIsInWorldCombat() then
    if self:OnIsSelfInWorldCombat() then
      return WorldCombatStatus.Enter
    end
    return WorldCombatStatus.Playing
  end
  return WorldCombatStatus.None
end

function WorldCombatModule:OnGetWorldCombatPhase(npc)
  if not npc then
    return nil
  end
  local record = self.records[npc:GetServerId()]
  if record then
    return record.baseInfo.Phase
  end
  return nil
end

function WorldCombatModule:OnIsInWorldCombat()
  return table.size(self.records) > 0
end

function WorldCombatModule:OnIsSelfInWorldCombat()
  return self.localPlayerBossId ~= DefaultCurrentBossNpcId
end

function WorldCombatModule:IsPlayerInWorldCombat(playerUin)
  for _, record in pairs(self.records or {}) do
    for _, playerId in ipairs(record.baseInfo.PlayersInCombat or {}) do
      if playerId == playerUin then
        return true
      end
    end
  end
  return false
end

function WorldCombatModule:OnIsNightmare()
  if self.localPlayerBossId == DefaultCurrentBossNpcId then
    return false
  end
  if not self.records then
    return false
  end
  local record = self:GetCurrentCombatRecord()
  if not record then
    return false
  end
  return record.bNightmare
end

function WorldCombatModule:OnIsACombatingBoss(severId)
  if self.records then
    return table.containsKey(self.records, severId)
  end
  return false
end

function WorldCombatModule:OnIsWorldCombatTarget(ID)
  if self.localPlayerBossId == DefaultCurrentBossNpcId then
    return false
  end
  return self.localPlayerBossId == ID
end

function WorldCombatModule:OnGetBossID()
  return self.localPlayerBossId
end

function WorldCombatModule:LockPlayer()
  local Player = _G.NRCModuleManager:DoCmd(_G.PlayerModuleCmd.GET_LOCAL_PLAYER)
  Player.inputComponent:SetInputEnable(self, false)
end

function WorldCombatModule:UnlockPlayer()
  local Player = _G.NRCModuleManager:DoCmd(_G.PlayerModuleCmd.GET_LOCAL_PLAYER)
  Player.inputComponent:SetInputEnable(self, true)
end

function WorldCombatModule:TryRegisterUpdate()
  if 0 == table.size(self.records) then
    _G.UpdateManager:Register(self)
    if self.bEditorPerformanceImprovement and _G.RocoEnv.IS_EDITOR then
      self.isEditor = _G.RocoEnv.IS_EDITOR
      _G.RocoEnv.IS_EDITOR = false
    end
  end
end

function WorldCombatModule:TryUnregisterUpdate()
  if 0 == table.size(self.records) then
    _G.UpdateManager:UnRegister(self)
    if self.isEditor then
      _G.RocoEnv.IS_EDITOR = self.isEditor
    end
  end
end

function WorldCombatModule:OnWorldCombatBegin(Action, Tag, BaseData)
  local bossId = Action.npc_id
  if table.containsKey(self.records, bossId) and self.records[bossId] then
    Log.Debug("WorldCombatModule:OnWorldCombatBegin combat has existed", bossId, Action.world_combat_id, Action.world_combat_cfg_id, Action.avatar_id, Action.world_combat_phase)
    return
  end
  local boss = _G.NRCModuleManager:DoCmd(_G.NPCModuleCmd.GetNpcByServerID, bossId)
  if not boss then
    Log.Debug("WorldCombatModule:OnWorldCombatBegin boss not existed", bossId)
    return
  end
  self:TryRegisterUpdate()
  if WorldCombatRecord.CheckSelfInThisAction(Action) then
    self:InternalEnterCombat(bossId)
    Log.Debug("WorldCombatModule:OnWorldCombatBegin self in combat", Action.npc_id, Action.world_combat_id, Action.world_combat_cfg_id)
  else
    Log.Debug("WorldCombatModule:OnWorldCombatBegin self not in combat", Action.npc_id, Action.world_combat_id, Action.world_combat_cfg_id)
  end
  local record = WorldCombatRecord()
  self.records[bossId] = record
  record:OnWorldCombatBegin(Action)
  self:UpdateRewardsFromServerData(boss.serverData)
end

function WorldCombatModule:OnWorldCombatFinish(Action, Tag, BaseData)
  Log.Debug("WorldCombatModule:OnWorldCombatFinish", Action.npc_id, Action.world_combat_id, Action.world_combat_cfg_id, Action.world_combat_res, Action.is_combat_avatar, Action.is_boss_challenge)
  if Action.world_combat_res == _G.ProtoEnum.WorldCombatRes.WCR_NPC_KILLED and not Action.is_boss_challenge and Action.is_combat_avatar then
    _G.NRCModuleManager:DoCmd(_G.TipsModuleCmd.Tips_ShowPropTips, TipObject.FromLeaderFight(Action, TipEnum.TipObjectType.LeaderFight), _G.ProtoCMD.ZoneSvrCmd.ZONE_BATTLE_FINISH_NOTIFY)
    Log.Debug("WorldCombatModule:OnWorldCombatFinish show tip", Action.npc_id, Action.world_combat_id, Action.world_combat_cfg_id)
  end
  local bossId = Action.npc_id
  local record = self.records[bossId]
  if not record then
    Log.Debug("WorldCombatModule:OnWorldCombatFinish combat not existed", bossId, Action.world_combat_id, Action.world_combat_cfg_id, Action.world_combat_res, Action.is_combat_avatar, Action.is_boss_challenge)
    return
  end
  if self.localPlayerBossId == bossId then
    self.localPlayerBossId = DefaultCurrentBossNpcId
    if self.currentRewardNpcId == bossId then
      self:UpdateRewardsData(bossId, nil)
      self.currentRewardNpcId = DefaultCurrentRewardNpcId
    end
    Log.Debug("WorldCombatModule:OnWorldCombatFinish self in combat", record:GetDebugInfo())
  else
    Log.Debug("WorldCombatModule:OnWorldCombatFinish self not in combat", record:GetDebugInfo())
  end
  record:OnWorldCombatFinish(Action)
  self.records[bossId] = nil
  self:ClearAllSkillActions(bossId)
  self:TryUnregisterUpdate()
end

function WorldCombatModule:OnWorldCombatEnter(Action, Tag, BaseData)
  local bossId = Action.npc_id
  local record = self.records[bossId]
  if not record then
    Log.Debug("WorldCombatModule:OnWorldCombatEnter combat not existed", bossId, Action.world_combat_id, Action.world_combat_cfg_id, Action.avatar_id)
    return
  end
  local LocalUIN = _G.NRCModuleManager:DoCmd(_G.PlayerModuleCmd.GET_LOCAL_UIN)
  if self.localPlayerBossId == Action.npc_id and LocalUIN == Action.avatar_id then
    Log.Debug("WorldCombatModule:OnWorldCombatEnter self already in different combat", self.localPlayerBossId, record:GetDebugInfo())
    return
  end
  if WorldCombatRecord.CheckSelfInThisAction(Action) then
    self:InternalEnterCombat(bossId)
    Log.Debug("WorldCombatModule:OnWorldCombatEnter self", record:GetDebugInfo())
  else
    Log.Debug("WorldCombatModule:OnWorldCombatEnter not self", record:GetDebugInfo(), Action.avatar_id)
  end
  record:OnWorldCombatEnter(Action)
end

function WorldCombatModule:OnWorldCombatExit(Action, Tag, BaseData)
  local bossId = Action.npc_id
  local record = self.records[bossId]
  if not record then
    Log.Debug("WorldCombatModule:OnWorldCombatExit combat not existed", bossId, Action.world_combat_id, Action.world_combat_cfg_id, Action.avatar_id, Action.world_combat_res)
    return
  end
  if WorldCombatRecord.CheckSelfInThisAction(Action) then
    self.localPlayerBossId = DefaultCurrentBossNpcId
    self.currentRewardNpcId = DefaultCurrentRewardNpcId
    self:DispatchAdditionalRewards(nil)
    Log.Debug("WorldCombatModule:OnWorldCombatExit self", record:GetDebugInfo())
  else
    Log.Debug("WorldCombatModule:OnWorldCombatExit not self", record:GetDebugInfo(), Action.avatar_id)
  end
  record:OnWorldCombatExit(Action)
end

function WorldCombatModule:OnWorldCombatPhaseUpdate(Action, Tag, BaseData)
  local record = self.records[Action.npc_id]
  if not record then
    Log.Debug("WorldCombatModule:OnWorldCombatPhaseUpdate combat not existed", Action.npc_id, Action.world_combat_id, Action.world_combat_phase)
    return
  end
  record:OnWorldCombatPhaseUpdate(Action)
end

function WorldCombatModule:InternalEnterCombat(npc_id)
  self.localPlayerBossId = npc_id
  self.currentRewardNpcId = npc_id
  if self.rewards then
    local reward = self.rewards[npc_id]
    if reward then
      self:DispatchAdditionalRewards(reward.extra_reward_list)
    end
  end
end

function WorldCombatModule:OnReconnect()
  if not self:OnIsInWorldCombat() then
    self:Log("reconnected, but no world combat mode")
    return
  end
  local Player = _G.NRCModuleManager:DoCmd(_G.PlayerModuleCmd.GET_LOCAL_PLAYER)
  if not Player then
    self:LogError("no player")
    return
  end
  if not Player.LogicStatusComponent then
    self:LogError("player has no LogicStatusComponent")
    return
  end
  if Player.LogicStatusComponent:GetStatus(Enum.SpaceActorLogicStatus.SALS_WORLD_COMBAT) then
    Log.Debug("WorldCombatModule:OnReconnect. player has SALS_WORLD_COMBAT, skip it")
    self.JustReconnected = true
    return
  end
  Log.Warning("Cleanup world combat on reconnect")
  self:ExitWorldCombatOnReconnect()
end

function WorldCombatModule:OnBossReconnect(npc, serverData, isReconnect)
  if not npc then
    Log.Debug("WorldCombatModule:OnBossReconnect. npc is nil !!!", isReconnect)
    return
  end
  if npc.config.genre ~= _G.Enum.ClientNpcType.CNT_PETBOSS then
    Log.Debug("WorldCombatModule:OnBossReconnect. npc is not boss", npc:DebugNPCNameAndID(), table.getKeyName(_G.Enum.ClientNpcType, npc.config.genre), isReconnect)
    return
  end
  Log.Debug("WorldCombatModule:OnBossReconnect", npc:DebugNPCNameAndID(), isReconnect)
  local bossId = npc:GetServerId()
  local record = self.records[bossId]
  if record then
    record:OnBossReconnect(npc, serverData, isReconnect)
    self:UpdateRewardsFromServerData(serverData)
  end
  local world_combat_info = serverData.world_combat_info
  if world_combat_info and world_combat_info.avatar_id ~= nil and #world_combat_info.avatar_id > 0 then
    if record then
      Log.Debug("WorldCombatModule:OnBossReconnect. record existed, update player list", npc:DebugNPCNameAndID(), isReconnect)
      local newEnteredPlayerList = {}
      for _, avatar_id in ipairs(world_combat_info.avatar_id) do
        if not table.contains(record.baseInfo.PlayersInCombat, avatar_id) then
          table.insert(newEnteredPlayerList, avatar_id)
        end
      end
      for _, avatar_id in ipairs(newEnteredPlayerList) do
        Log.Debug("WorldCombatModule:OnBossReconnect. new player enter", npc:DebugNPCNameAndID(), isReconnect, avatar_id)
        local EnterAction = _G.ProtoMessage:newSpaceAct_WorldCombatEnter()
        EnterAction.npc_id = bossId
        EnterAction.avatar_id = avatar_id
        EnterAction.world_combat_id = world_combat_info.world_combat_id
        EnterAction.world_combat_cfg_id = world_combat_info.world_combat_cfg_id
        EnterAction.world_combat_phase = world_combat_info.world_combat_phase
        self:OnWorldCombatEnter(EnterAction)
      end
      local newExitedPlayerList = {}
      for _, avatar_id in ipairs(record.baseInfo.PlayersInCombat) do
        if not table.contains(world_combat_info.avatar_id, avatar_id) then
          table.insert(newExitedPlayerList, avatar_id)
        end
      end
      for _, avatar_id in ipairs(newExitedPlayerList) do
        Log.Debug("WorldCombatModule:OnBossReconnect. new player exit", npc:DebugNPCNameAndID(), isReconnect, avatar_id)
        local ExitAction = _G.ProtoMessage:newSpaceAct_WorldCombatEnter()
        ExitAction.npc_id = bossId
        ExitAction.avatar_id = avatar_id
        ExitAction.world_combat_id = world_combat_info.world_combat_id
        ExitAction.world_combat_cfg_id = world_combat_info.world_combat_cfg_id
        ExitAction.world_combat_phase = world_combat_info.world_combat_phase
        self:OnWorldCombatExit(ExitAction)
      end
    else
      Log.Debug("WorldCombatModule:OnBossReconnect. record not existed, new combat will begin", npc:DebugNPCNameAndID(), isReconnect)
      local BeginAction = _G.ProtoMessage:newSpaceAct_WorldCombatBegin()
      BeginAction.npc_id = bossId
      BeginAction.avatar_id = world_combat_info.avatar_id
      BeginAction.world_combat_id = world_combat_info.world_combat_id
      BeginAction.world_combat_cfg_id = world_combat_info.world_combat_cfg_id
      BeginAction.world_combat_phase = world_combat_info.world_combat_phase
      self:OnWorldCombatBegin(BeginAction)
    end
  elseif record then
    Log.Debug("WorldCombatModule:OnBossReconnect. no combat info but record existed, combat will finish", npc:DebugNPCNameAndID(), isReconnect)
    local FinishAction = _G.ProtoMessage:newSpaceAct_WorldCombatFinish()
    FinishAction.npc_id = bossId
    self:OnWorldCombatFinish(FinishAction)
  end
end

function WorldCombatModule:ExitWorldCombatOnReconnect()
  Log.Debug("WorldCombatModule:ExitWorldCombatOnReconnect, exit first")
  self.JustReconnected = nil
  self:TryExitCurrentCombat()
end

function WorldCombatModule:TryExitCurrentCombat()
  local record = self:GetCurrentCombatRecord()
  if not record then
    return
  end
  local exitAction = _G.ProtoMessage:newSpaceAct_WorldCombatExit()
  exitAction.avatar_id = _G.NRCModuleManager:DoCmd(_G.PlayerModuleCmd.GET_LOCAL_UIN)
  exitAction.world_combat_id = record.baseInfo.WorldCombatId
  exitAction.npc_id = record.baseInfo.NpcId
  self:OnWorldCombatExit(exitAction)
  if 0 == #record.baseInfo.PlayersInCombat then
    local finishAction = _G.ProtoMessage:newSpaceAct_WorldCombatFinish()
    finishAction.npc_id = record.baseInfo.NpcId
    self:OnWorldCombatFinish(finishAction)
  end
end

function WorldCombatModule:OnWorldCombatSkillCast(Action, Tag, BaseData)
  local caster = _G.NRCModuleManager:DoCmd(_G.NPCModuleCmd.GetNpcByServerID, Action.actor_id)
  local castResult = Enum.WorldSkillValidResult.WSVR_SUCCESS
  caster:EnsureComponent(WorldCombatSkillComponent):OnServerValidBack(castResult)
end

function WorldCombatModule:OnWorldCombatSkillSpawnNpc(Action, Tag, BaseData)
end

function WorldCombatModule:OnWorldCombatSkillSpawnBullet(Action, Tag, BaseData)
  local missileModule = NRCModuleManager:GetModule("MissileModule")
  local caster = _G.NRCModuleManager:DoCmd(_G.NPCModuleCmd.GetNpcByServerID, Action.actor_id)
  if not caster:EnsureComponent(WorldCombatSkillComponent).currentContext then
    Log.Debug("Spawn bullet after skill end!!!")
    return
  end
  local targetId = Action.skill_spawn_bullet_info.target_id
  local target = _G.NRCModuleManager:DoCmd(_G.NPCModuleCmd.GetNpcByServerID, targetId) or NRCModuleManager:DoCmd(_G.PlayerModuleCmd.GetPlayerByServerID, targetId)
  local init_dir = SceneUtils.ServerPos2ClientPos(Action.skill_spawn_bullet_info.init_dir, 10)
  missileModule:CreateMissile(Action.skill_spawn_bullet_info.bullet_id, caster, target, Action.skill_spawn_bullet_info.target_pos, Action.skill_spawn_bullet_info.skill_id, Action.skill_spawn_bullet_info.action_idx, nil, Action.skill_spawn_bullet_info.init_pos, init_dir)
end

function WorldCombatModule:OnWorldCombatSkillFireBullet(Action, Tag, BaseData)
  local missileModule = NRCModuleManager:GetModule("MissileModule")
  missileModule:LaunchMissile(Action.skill_fire_bullet_info.bullet_id)
end

function WorldCombatModule:OnWorldCombatSkillHit(Action, Tag, BaseData)
end

function WorldCombatModule:OnWorldCombatSkillSettle(Action, Tag, BaseData)
end

function WorldCombatModule:OnExitRsp(Rsp)
end

function WorldCombatModule:OnReEnterAreaRsp(Rsp)
  if Rsp.ret_info.ret_code ~= ProtoEnum.MOBA_RET.SceneErr.ERR_SCENE_PLAYER_OUT_WORLD_COMBAT_AREA then
    self.LeavingTimer = -1
  end
end

function WorldCombatModule:OnLeaveAreaRsp(Rsp)
  if Rsp.ret_info.ret_code ~= ProtoEnum.MOBA_RET.SceneErr.ERR_SCENE_PLAYER_IN_WORLD_COMBAT_AREA then
    self.LeavingTimer = LeavingTime
  end
end

function WorldCombatModule:OnEnterWorldCombatRsp(Rsp)
end

function WorldCombatModule:OnExitButtonClicked()
  Log.Warning("WorldCombatModule:OnExitButtonClicked deprecated !!!")
end

function WorldCombatModule:ExitDialogCallback(Type)
  Log.Warning("WorldCombatModule:ExitDialogCallback deprecated !!!", Type)
  self.ExitContext = nil
  if not Type then
    return
  end
  if self.Status ~= WorldCombatStatus.Playing then
    Log.Error("\232\175\183\230\177\130\231\187\147\230\157\159\233\166\150\233\162\134\230\136\152\231\138\182\230\128\129\228\184\141\231\172\166", table.getKeyName(WorldCombatStatus, self.Status))
    return
  end
  local Req = _G.ProtoMessage:newZoneSceneWorldCombatExitReq()
  Req.npc_id = self.BossActorID
  _G.ZoneServer:SendWithHandler(ProtoCMD.ZoneSvrCmd.ZONE_SCENE_WORLD_COMBAT_EXIT_REQ, Req, self, self.OnExitRsp, true, false)
end

function WorldCombatModule:OnRelogin()
  if self.ExitContext then
    self.ExitContext:Close()
  end
  self.ExitContext = nil
end

function WorldCombatModule:LoadMapStart(SameScene)
end

function WorldCombatModule:LoadMapFinish()
end

function WorldCombatModule:OnDestruct()
end

function WorldCombatModule:OnGetShieldData()
  local record = self:GetCurrentCombatRecord()
  if record and record.shieldInfo then
    return record.shieldInfo.shield_state, record.shieldInfo.shield_max_value, record.shieldInfo.shield_value
  end
  return WorldCombatModuleEnum.ShieldState.Hidden, 0, 0
end

function WorldCombatModule:OnBattleRealEnd()
  if self.DelayCheckDelegate then
    _G.DelayManager:CancelDelayById(self.DelayCheckDelegate)
    self.DelayCheckDelegate = nil
  end
  self:ConsumeCachedActorTagForBoss()
  self.DelayCheckDelegate = _G.DelayManager:DelaySeconds(1, self.ConsumeCachedActorTagForBoss, self)
end

function WorldCombatModule:ConsumeCachedActorTagForBoss()
  if self:OnIsInWorldCombat() then
    _G.NRCModuleManager:DoCmd(_G.SceneModuleCmd.ConsumeCachedActorTag, self:OnGetBossID())
  end
  self.DelayCheckDelegate = nil
end

function WorldCombatModule:OnGetBossLocation(bossContentId)
  local boss
  if bossContentId then
    boss = _G.NRCModuleManager:DoCmd(_G.NPCModuleCmd.GetNpcByRefreshID, bossContentId)
  end
  if not boss then
    local bossId = _G.NRCModuleManager:DoCmd(_G.WorldCombatModuleCmd.GetBossID)
    boss = _G.NRCModeManager:DoCmd(_G.NPCModuleCmd.GetNpcByServerID, bossId)
  end
  if not boss and bossContentId then
    local NPC_REFRESH_CONTENT_CONF = _G.DataConfigManager:GetTable(DataConfigManager.ConfigTableId.NPC_REFRESH_CONTENT_CONF):GetAllDatas()
    local RefreshConf = NPC_REFRESH_CONTENT_CONF[bossContentId]
    if not RefreshConf or not RefreshConf.refresh_param then
      return
    end
    local AreaConf = _G.DataConfigManager:GetAreaConf(RefreshConf.refresh_param, true)
    if not AreaConf or 0 == #AreaConf.pos then
      return
    end
    local Pos = AreaConf.pos[1]
    local Position = UE.FVector(Pos.position_xyz[1] + 100, Pos.position_xyz[2] + 100, Pos.position_xyz[3] + 780)
    return Position
  end
  if boss then
    local hidComp = boss.HiddenComponent
    if hidComp then
      local mimicTarget = hidComp:GetMimicObject()
      if mimicTarget then
        return mimicTarget:Abs_K2_GetActorLocation()
      end
    end
  end
  return boss:GetActorLocation()
end

function WorldCombatModule:SetInBattle(bInBattle, npcIds)
  self.InBattle = bInBattle
  if npcIds then
    for idx, npcId in pairs(npcIds) do
      Log.Debug("WorldCombatModule:SetInBattle", bInBattle, idx, npcId)
      local record = self.records[npcId]
      if record then
        record:SetAirWallVisible(not bInBattle)
      end
    end
  end
end

function WorldCombatModule:GetInBattle()
  return self.InBattle
end

function WorldCombatModule:OnIsInOfflineMode()
  local localMode = NRCModeManager:GetMode("LocalMode")
  if localMode then
    return true
  end
  return false
end

function WorldCombatModule:AddSkillAction(action, bossId)
  if not self.currSkillActions[bossId] then
    self.currSkillActions[bossId] = {}
  end
  table.insert(self.currSkillActions[bossId], action)
end

function WorldCombatModule:RemoveSkillAction(action, bossId)
  if not self.currSkillActions[bossId] then
    return
  end
  table.removeValue(self.currSkillActions[bossId], action)
end

function WorldCombatModule:ClearAllSkillActions(bossId)
  if not self.currSkillActions[bossId] then
    return
  end
  for _, action in ipairs(self.currSkillActions[bossId]) do
    action:Finish()
  end
  table.clear(self.currSkillActions)
end

function WorldCombatModule:OnWorldCombatDotsSkillCast(Action, Tag, BaseData)
  local caster = _G.NRCModuleManager:DoCmd(_G.NPCModuleCmd.GetNpcByServerID, Action.actor_id)
  if not caster then
    return
  end
  local worldCombatAction = WorldCombatActionFactory:Get(caster, Enum.ActionType.ACT_DOTS_WORLD_COMBAT_SKILL_CAST, Action.skill_cast_info)
  worldCombatAction:Execute(self)
  Log.Debug("WorldCombatModule:OnWorldCombatDotsSkillCast Set Boss Pos", Action.actor_id, caster:GetActorLocation(), Action.skill_cast_info.skill_id, Action.cast_point.pos.x, Action.cast_point.pos.y, Action.cast_point.pos.z, Action.skill_cast_info.target_id)
  if Action.is_need_sync_pos then
    _G.NRCModuleManager:DoCmd(_G.WorldCombatModuleCmd.SetBossPosAndDir, Action.actor_id, Action.cast_point)
  end
end

function WorldCombatModule:OnWorldCombatDotsSkillEnd(Action, Tag, BaseData)
  local caster = _G.NRCModuleManager:DoCmd(_G.NPCModuleCmd.GetNpcByServerID, Action.actor_id)
  if not caster then
    return
  end
  local worldCombatAction = WorldCombatActionFactory:Get(caster, Enum.ActionType.ACT_DOTS_WORLD_COMBAT_SKILL_END, Action.skill_end_info)
  worldCombatAction:Execute(self)
  if Action.skill_end_info.end_reason == UE.ESkillActionResult.SkillActionResultInterrupted then
    Log.Debug("WorldCombatModule:OnWorldCombatDotsSkillEnd: \232\162\171\230\152\159\230\152\159\233\173\148\230\179\149\229\135\187\228\184\173\232\144\189\229\156\176", Action.skill_end_info.skill_id)
    return
  end
  Log.Debug("WorldCombatModule:OnWorldCombatDotsSkillEnd Set Boss Pos", Action.actor_id, caster:GetActorLocation(), Action.skill_end_info.skill_id, Action.cast_end_point.pos.x, Action.cast_end_point.pos.y, Action.cast_end_point.pos.z)
  if Action.is_need_sync_pos then
    _G.NRCModuleManager:DoCmd(_G.WorldCombatModuleCmd.SetBossPosAndDir, Action.actor_id, Action.cast_end_point)
  end
end

function WorldCombatModule:OnWorldCombatDotsSkillCrush(Action, Tag, BaseData)
  if self:OnIsInOfflineMode() then
    return
  end
  local caster = _G.NRCModuleManager:DoCmd(_G.NPCModuleCmd.GetNpcByServerID, Action.actor_id)
  if not caster then
    return
  end
  local worldCombatAction = WorldCombatActionFactory:Get(caster, Enum.ActionType.ACT_DOTS_WORLD_COMBAT_CRUSH, Action.skill_crush_info)
  worldCombatAction:Execute(self)
end

function WorldCombatModule:OnWorldCombatDotsSkillRotate(Action, Tag, BaseData)
  if self:OnIsInOfflineMode() then
    return
  end
  local caster = _G.NRCModuleManager:DoCmd(_G.NPCModuleCmd.GetNpcByServerID, Action.actor_id)
  if not caster then
    return
  end
  local worldCombatAction = WorldCombatActionFactory:Get(caster, Enum.ActionType.ACT_DOTS_WORLD_COMBAT_Rotation, Action.skill_rotate_info)
  worldCombatAction:Execute(self)
end

function WorldCombatModule:OnWorldCombatDotsSkillHit(Action, Tag, BaseData)
  if self:OnIsInOfflineMode() then
    return
  end
  local caster = _G.NRCModuleManager:DoCmd(_G.NPCModuleCmd.GetNpcByServerID, Action.actor_id)
  if not caster then
    return
  end
  local fxPos = SceneUtils.ServerPos2ClientPos(Action.skill_hit_info.hit_point.pos, 1)
  if UE.UKismetMathLibrary.Vector_IsNearlyZero(fxPos) then
    return
  end
  local worldCombatAction = WorldCombatActionFactory:Get(caster, Enum.ActionType.ACT_DOTS_WORLD_COMBAT_Hit, Action.skill_hit_info)
  worldCombatAction:Execute(self)
end

function WorldCombatModule:OnWorldCombatDotsSkillLookAt(Action, Tag, BaseData)
  if self:OnIsInOfflineMode() then
    return
  end
  local caster = _G.NRCModuleManager:DoCmd(_G.NPCModuleCmd.GetNpcByServerID, Action.actor_id)
  if not caster then
    return
  end
  local worldCombatAction = WorldCombatActionFactory:Get(caster, Enum.ActionType.ACT_DOTS_WORLD_COMBAT_LookAt, Action.skill_lookat_info)
  worldCombatAction:Execute(self)
end

function WorldCombatModule:OnWorldCombatDotsSkillCrushEnd(Action, Tag, BaseData)
  if self:OnIsInOfflineMode() then
    return
  end
  local caster = _G.NRCModuleManager:DoCmd(_G.NPCModuleCmd.GetNpcByServerID, Action.actor_id)
  if not caster then
    return
  end
  local worldCombatAction = WorldCombatActionFactory:Get(caster, Enum.ActionType.ACT_DOTS_WORLD_COMBAT_CRUSH_END, Action.skill_crush_end_info)
  worldCombatAction:Execute(self)
end

function WorldCombatModule:OnWorldCombatDotsSkillMissileLaunch(Action, Tag, BaseData)
  if self:OnIsInOfflineMode() then
    return
  end
  local caster = _G.NRCModuleManager:DoCmd(_G.NPCModuleCmd.GetNpcByServerID, Action.actor_id)
  if not caster then
    return
  end
  local worldCombatAction = WorldCombatActionFactory:Get(caster, Enum.ActionType.ACT_DOTS_WORLD_COMBAT_MISSILE_LAUNCH, Action.skill_missile_launch)
  worldCombatAction:Execute(self)
end

function WorldCombatModule:OnWorldCombatDotsSkillMissileDestroy(Action, Tag, BaseData)
  if self:OnIsInOfflineMode() then
    return
  end
  local caster = _G.NRCModuleManager:DoCmd(_G.NPCModuleCmd.GetNpcByServerID, Action.actor_id)
  if not caster then
    return
  end
  local worldCombatAction = WorldCombatActionFactory:Get(caster, Enum.ActionType.ACT_DOTS_WORLD_COMBAT_MISSILE_DESTROY, Action.skill_missile_destroy)
  worldCombatAction:Execute(self)
end

function WorldCombatModule:OnWorldCombatDotsSkillMissileStopTrace(Action, Tag, BaseData)
  if self:OnIsInOfflineMode() then
    return
  end
  local caster = _G.NRCModuleManager:DoCmd(_G.NPCModuleCmd.GetNpcByServerID, Action.actor_id)
  if not caster then
    return
  end
  local worldCombatAction = WorldCombatActionFactory:Get(caster, Enum.ActionType.ACT_DOTS_WORLD_COMBAT_MISSILE_STOP_TRACE, Action.skill_missile_stop_trace)
  worldCombatAction:Execute(self)
end

function WorldCombatModule:OnWorldCombatDotsSkillJump(Action, Tag, BaseData)
  if self:OnIsInOfflineMode() then
    return
  end
  local caster = _G.NRCModuleManager:DoCmd(_G.NPCModuleCmd.GetNpcByServerID, Action.actor_id)
  if not caster then
    return
  end
  local worldCombatAction = WorldCombatActionFactory:Get(caster, Enum.ActionType.ACT_DOTS_WORLD_COMBAT_JUMP, Action.skill_jump)
  worldCombatAction:Execute(self)
end

function WorldCombatModule:OnWorldCombatDotsSkillJumpCancel(Action, Tag, BaseData)
  if self:OnIsInOfflineMode() then
    return
  end
  local caster = _G.NRCModuleManager:DoCmd(_G.NPCModuleCmd.GetNpcByServerID, Action.actor_id)
  if not caster then
    return
  end
  local worldCombatAction = WorldCombatActionFactory:Get(caster, Enum.ActionType.ACT_DOTS_WORLD_COMBAT_JUMP_CANCEL, Action.skill_jump_cancel)
  worldCombatAction:Execute(self)
end

function WorldCombatModule:OnWorldCombatDotsSkillJumpEnd(Action, Tag, BaseData)
  if self:OnIsInOfflineMode() then
    return
  end
  local caster = _G.NRCModuleManager:DoCmd(_G.NPCModuleCmd.GetNpcByServerID, Action.actor_id)
  if not caster then
    return
  end
  local worldCombatAction = WorldCombatActionFactory:Get(caster, Enum.ActionType.ACT_DOTS_WORLD_COMBAT_JUMP_END, Action.skill_jump_end)
  worldCombatAction:Execute(self)
end

function WorldCombatModule:OnWorldCombatDotsSkillRcd(Action, Tag, BaseData)
  if self:OnIsInOfflineMode() then
    return
  end
  local caster = _G.NRCModuleManager:DoCmd(_G.NPCModuleCmd.GetNpcByServerID, Action.actor_id)
  if not caster then
    return
  end
  local worldCombatAction = WorldCombatActionFactory:Get(caster, Enum.ActionType.ACT_DOTS_WORLD_COMBAT_RCD, Action.skill_rcd)
  worldCombatAction:Execute(self)
end

function WorldCombatModule:OnWorldCombatDotsSkillRcdEnd(Action, Tag, BaseData)
  if self:OnIsInOfflineMode() then
    return
  end
  local caster = _G.NRCModuleManager:DoCmd(_G.NPCModuleCmd.GetNpcByServerID, Action.actor_id)
  if not caster then
    return
  end
  local worldCombatAction = WorldCombatActionFactory:Get(caster, Enum.ActionType.ACT_DOTS_WORLD_COMBAT_RCD_END, Action.skill_rcd_end)
  worldCombatAction:Execute(self)
end

function WorldCombatModule:OnWorldCombatDotsShowHideChange(Action, Tag, BaseData)
  if self:OnIsInOfflineMode() then
    return
  end
  local caster = _G.NRCModuleManager:DoCmd(_G.NPCModuleCmd.GetNpcByServerID, Action.actor_id)
  if not caster then
    return
  end
  local worldCombatAction = WorldCombatActionFactory:Get(caster, Enum.ActionType.ACT_DOTS_WORLD_COMBAT_SHOW_HIDE_CHANGE, Action.show_hide_info)
  worldCombatAction:Execute(self)
end

function WorldCombatModule:OnWorldCombatDotsSkillPosLerpSync(Action, Tag, BaseData)
  if self:OnIsInOfflineMode() then
    return
  end
  local caster = _G.NRCModuleManager:DoCmd(_G.NPCModuleCmd.GetNpcByServerID, Action.actor_id)
  if not caster then
    return
  end
  local worldCombatAction = WorldCombatActionFactory:Get(caster, Enum.ActionType.ACT_DOTS_WORLD_COMBAT_LERP_POS_DIR, Action.info)
  worldCombatAction:Execute(self)
end

function WorldCombatModule:OnWorldCombatDotsSkillAnimCancel(Action, Tag, BaseData)
  if self:OnIsInOfflineMode() then
    return
  end
  local caster = _G.NRCModuleManager:DoCmd(_G.NPCModuleCmd.GetNpcByServerID, Action.actor_id)
  if not caster then
    return
  end
  local worldCombatAction = WorldCombatActionFactory:Get(caster, Enum.ActionType.ACT_DOTS_WORLD_COMBAT_ANIM_CANCEL, Action.info)
  worldCombatAction:Execute(self)
end

function WorldCombatModule:OnWorldCombatDotsSkillSelectPos(Action, Tag, BaseData)
  if self:OnIsInOfflineMode() then
    return
  end
  local caster = _G.NRCModuleManager:DoCmd(_G.NPCModuleCmd.GetNpcByServerID, Action.actor_id)
  if not caster then
    return
  end
  local worldCombatAction = WorldCombatActionFactory:Get(caster, Enum.ActionType.ACT_DOTS_WORLD_COMBAT_SELECT_POS, Action.skill_select_pos)
  worldCombatAction:Execute(self)
end

function WorldCombatModule:OnServerNotifyTips(Action)
  local Conf = _G.DataConfigManager:GetLocalizationConf(Action.text_prompts_id)
  local Delay
  if Conf and Conf.id == "worldcombat_tips_1" or Conf.id == "worldcombat_tips_2" or Conf.id == "worldcombat_tips_3" then
    local localPlayer = _G.NRCModuleManager:DoCmd(_G.PlayerModuleCmd.GET_LOCAL_PLAYER)
    if localPlayer.statusComponent:HasStatus(_G.ProtoEnum.WorldPlayerStatusType.WPST_DEATH) then
      return
    end
    Delay = 5.5
  end
  if not Conf then
    return
  end
  if not UE4Helper.GetEnableWorldRendering() then
    self.cachedServerTips = {}
    self.cachedServerTips.msg = Conf.msg
    self.cachedServerTips.delay = Delay
  else
    _G.NRCModuleManager:DoCmd(_G.TipsModuleCmd.TopHud_ShowTips, Conf.msg, Delay, nil, 2)
  end
end

function WorldCombatModule:OnSetBossPosAndDir(bossId, newPoint, lerpDuration)
  lerpDuration = lerpDuration or 0.3
  local boss = _G.NRCModeManager:DoCmd(_G.NPCModuleCmd.GetNpcByServerID, bossId)
  if boss and boss.viewObj then
    local pos = SceneUtils.ServerPos2ClientPos(newPoint.pos)
    local rotator = SceneUtils.ServerPos2ClientRotator(newPoint.dir)
    local halfHeight = boss:GetScaledHalfHeight()
    local moveComp = boss.viewObj.GetMovementComponent and boss.viewObj:GetMovementComponent() or nil
    if moveComp and (moveComp:IsHovering() or moveComp:IsFlying() or moveComp:IsSwimming()) then
      pos.Z = pos.Z + halfHeight
    else
      local BossRootComp = boss.viewObj:K2_GetRootComponent()
      local MoveIgnoreActors = BossRootComp and BossRootComp:CopyArrayOfMoveIgnoreActors():ToTable() or {}
      pos = SceneUtils.GetPosInLand(pos, halfHeight, halfHeight, 5000, MoveIgnoreActors, {}, nil, true, false, true) or pos + UE.FVector(0, 0, halfHeight)
    end
    boss:EnsureComponent(OverlapAwareVisibilityComponent):CheckInBoundAndMarkHidden(true, true, false, -5, true)
    if not boss:EnsureComponent(WorldCombatSkillComponent).inPosDirLerp then
      boss.viewObj:Abs_K2_SetActorLocation(pos, false, nil, false)
      local rootComp = boss.viewObj:K2_GetRootComponent()
      if rootComp and boss:GetActorRotation() ~= rotator then
        rootComp:MoveComponent(_G.FVectorZero, rotator:ToQuat(), false, nil, 2, UE.ETeleportType.ResetPhysics)
      end
    end
    Log.Debug("WorldCombatModule:OnSetBossPosAndDir Set boss pos and dir", pos, boss:GetActorLocation(), rotator, boss:GetActorRotation())
  end
end

function WorldCombatModule:CheckBossPosNeedLerp(boss, targetPos, posLerpThreshold)
  return posLerpThreshold < (targetPos - boss:GetActorLocation()):Size()
end

function WorldCombatModule:CheckBossDirNeedLerp(boss, targetDir, dirLerpThreshold)
  return dirLerpThreshold < _G.LuaMathUtils.AngleBetweenVectors(boss:GetForwardVector(), targetDir)
end

function WorldCombatModule:AddBossLerpAction(boss, pos, dir, lerpDuration, posLerpThreshold, dirLerpThreshold, onLerpDone, onParams)
  if not self:CheckCanAddLerpAction() then
    return
  end
  local lerpAction = BossPosDirLerpAction(boss, pos, dir, lerpDuration, posLerpThreshold, dirLerpThreshold, onLerpDone, onParams)
  table.insert(self.WaitLerpActions, lerpAction)
  return lerpAction
end

function WorldCombatModule:RemoveBossLerpAction(lerpAction)
  table.removeValue(self.WaitLerpActions, lerpAction)
end

function WorldCombatModule:CheckCanAddLerpAction()
  if table.size(self.records) <= 0 then
    return false
  end
  if self.Status == WorldCombatStatus.None then
    return false
  end
  if self.bInBattle then
    return false
  end
  local LocalPlayer = _G.NRCModuleManager:DoCmd(_G.PlayerModuleCmd.GET_LOCAL_PLAYER)
  if not LocalPlayer then
    return false
  end
  if self.JustReconnected and not LocalPlayer:IsLogicStatus(ProtoEnum.SpaceActorLogicStatus.SALS_WORLD_COMBAT) then
    return false
  end
  return true
end

function WorldCombatModule:ClearWaitLerpActions()
  for _, action in ipairs(self.WaitLerpActions) do
    action.runner:SetActorLocation(action.targetPos)
    action.runner:SetActorRotation(action.targetDir:ToRotator())
    if type(action.callBack) == "function" then
      action.callBack(table.unpack(action.params))
    end
  end
  self.WaitLerpActions = {}
end

function WorldCombatModule:GetCanDrawDebug()
  if _G.RocoEnv.IS_SHIPPING then
    return false
  end
  return self.bDrawDebugFlag == true
end

function WorldCombatModule:OnEnterVisit()
  local playerUin = _G.DataModelMgr.PlayerDataModel:GetPlayerInfo().brief_info.uin
  local ownerUin = _G.DataModelMgr.PlayerDataModel:GetPlayerVisitOwnerUin()
  self.isVisitor = playerUin ~= ownerUin
end

function WorldCombatModule:OnLeaveVisit()
  if self.isVisitor then
    Log.Debug("WorldCombatModule:OnLeaveVisit self is visitor, try exit current combat")
    self:TryExitCurrentCombat()
    self.isVisitor = false
  end
end

function WorldCombatModule:OnLoadingClosed()
  if self.cachedServerTips ~= nil then
    _G.NRCModuleManager:DoCmd(_G.TipsModuleCmd.TopHud_ShowTips, self.cachedServerTips.msg, self.cachedServerTips.delay)
    self.cachedServerTips = nil
  end
end

function WorldCombatModule:SwitchAIServerError()
  if _G.DataModelMgr.PlayerDataModel and _G.DataModelMgr.PlayerDataModel:GetPlayerInfo() then
    local playerUin = _G.DataModelMgr.PlayerDataModel:GetPlayerUin()
    local req = _G.ProtoMessage:newZoneGmScenesvrErrEchoReq()
    req.uin = playerUin
    req.status = not self.bShowAIServerError
    _G.ZoneServer:SendWithHandler(_G.ProtoCMD.ZoneSvrGmCmd.ZONE_GM_SCENESVR_ERR_ECHO_REQ, req, self, self.OnGmScenesvrErrEcho)
  end
end

function WorldCombatModule:OnGmScenesvrErrEcho(rsp)
  if rsp and rsp.ret_info and 0 == rsp.ret_info.ret_code then
    self.bShowAIServerError = not self.bShowAIServerError
    _G.NRCModuleManager:DoCmd(_G.TipsModuleCmd.TopHud_ShowTips, string.format("\230\152\175\229\144\166\232\142\183\229\143\150\230\156\141\229\138\161\229\153\168AI\230\138\165\233\148\153\239\188\154%s", tostring(self.bShowAIServerError)), 1, nil, 5)
  end
end

function WorldCombatModule:ShowServerError(Action, Tag, BaseData)
  if Action and Action.err_str then
    local message = "\230\156\141\229\138\161\229\153\168AI\230\138\165\233\148\153:" .. Action.err_str
    _G.NRCModuleManager:DoCmd(_G.TipsModuleCmd.TopHud_ShowTips, message, nil, nil, 5)
    Log.Debug(message)
  end
end

function WorldCombatModule:ExtraRewardUpdate(Action)
  if not Action then
    Log.Debug("WorldCombatModule:ExtraRewardUpdate: Action is nil")
    return
  end
  Log.Debug("WorldCombatRecord:ExtraRewardUpdate", Action.npc_id, Action.world_combat_id)
  self:UpdateRewardsData(Action.npc_id, Action.extra_reward_list)
end

function WorldCombatModule:GetExtraRewardList()
  if self.currentRewardNpcId == DefaultCurrentRewardNpcId then
    return nil
  end
  local reward = self.rewards[self.currentRewardNpcId]
  if reward then
    return reward.extra_reward_list
  end
  return nil
end

function WorldCombatModule:UpdateRewardsFromServerData(serverData)
  if not serverData then
    return
  end
  local npcId = serverData.base.actor_id
  if serverData.world_combat_info and serverData.world_combat_info.extra_reward_info then
    local LocalUIN = _G.NRCModuleManager:DoCmd(_G.PlayerModuleCmd.GET_LOCAL_UIN)
    Log.Debug("WorldCombatModule:UpdateRewardsFromServerData From Boss", LocalUIN, #serverData.world_combat_info.extra_reward_info)
    for idx, extra_reward_info in ipairs(serverData.world_combat_info.extra_reward_info) do
      if extra_reward_info.avatar_id == LocalUIN then
        Log.Debug("WorldCombatRecord:UpdateRewardsFromServerData From Boss Found Self Info", npcId, LocalUIN, idx)
        self:UpdateRewardsData(npcId, extra_reward_info.extra_reward_list)
        break
      end
    end
  end
  if serverData.misc_info and serverData.misc_info.box_extra_reward_info_list then
    Log.Debug("WorldCombatModule:UpdateRewardsFromServerData From Reward Box", npcId, serverData.npc_base.npc_content_cfg_id)
    self.currentRewardNpcId = npcId
    self:UpdateRewardsData(npcId, serverData.misc_info.box_extra_reward_info_list, true)
  end
end

function WorldCombatModule:ExtraRewardCollected(serverData)
  self.currentRewardNpcId = DefaultCurrentRewardNpcId
  self.rewards[serverData.base.actor_id] = nil
  self:DispatchAdditionalRewards(nil)
end

function WorldCombatModule:UpdateRewardsData(npcId, rewardInfo, bIsNotCollected)
  local reward = self.rewards[npcId]
  if not reward then
    reward = {}
    self.rewards[npcId] = reward
  end
  reward.extra_reward_list = rewardInfo
  reward.rewardsNotCollected = bIsNotCollected
  if npcId == self.currentRewardNpcId then
    self:DispatchAdditionalRewards(rewardInfo)
  end
end

function WorldCombatModule:DispatchAdditionalRewards(rewards)
  if rewards then
    _G.NRCModuleManager:DoCmd(_G.MainUIModuleCmd.OpenAdditionalTarget, rewards)
  else
    _G.NRCEventCenter:DispatchEvent(NPCModuleEvent.WorldCombatBoxInvisible)
  end
end

function WorldCombatModule:IsPointInAnyWorldCombatArea(pos2d)
  for _, record in ipairs(self.records) do
    if record.baseInfo and record:IsPointInRegion(pos2d) then
      return true
    end
  end
  return false
end

function WorldCombatModule:OnBossInited(npc)
  if not npc then
    return
  end
  Log.Debug("WorldCombatModule:OnBossInited", npc:DebugNPCNameAndID())
  local bossInfo = WorldCombatBossInfo.GetBossInfoFromNpc(npc)
  if not bossInfo then
    return
  end
  if not self.bossInfos then
    self.bossInfos = {}
  end
  local npcId = npc:GetServerId()
  self.bossInfos[npcId] = bossInfo
  npc:AddEventListener(self, NPCModuleEvent.On_NPC_LEAVE, self.OnBossDestroyed)
end

function WorldCombatModule:OnBossDestroyed(npc)
  if not npc then
    return
  end
  Log.Debug("WorldCombatModule:OnBossDestroyed", npc:DebugNPCNameAndID())
  if not self.bossInfos then
    return
  end
  local npcId = npc:GetServerId()
  self.bossInfos[npcId] = nil
end

function WorldCombatModule:OnCheckPointInBossArea(position, bSimple)
  if not self.bossInfos or 0 == #self.bossInfos then
    return false, nil
  end
  for _, bossInfo in pairs(self.bossInfos) do
    if bSimple then
      if bossInfo:IsPointInCircle(position) then
        return true, bossInfo
      end
    elseif bossInfo:IsPointInPolygon(position) then
      return true, bossInfo
    end
  end
  return false, nil
end

function WorldCombatModule:OnCheckCircleInBossArea(position, radius, bSimple)
  if not self.bossInfos then
    return false, nil
  end
  for _, bossInfo in pairs(self.bossInfos) do
    if bSimple then
      if bossInfo:IsCircleOverlap(position, radius) then
        return true, bossInfo
      end
    elseif bossInfo:IsCircleInPolygon(position, radius) then
      return true, bossInfo
    end
  end
  return false, nil
end

function WorldCombatModule:OnToggleEditorPerformanceImprovement()
  self.bEditorPerformanceImprovement = not self.bEditorPerformanceImprovement
end

function WorldCombatModule:OnAddHideNpcViews(npcView)
  if not self.hideNpcViews then
    self.hideNpcViews = {}
  end
  if not UE.UObject.IsValid(npcView) then
    return
  end
  if table.contains(self.hideNpcViews, npcView) then
    return
  end
  table.insert(self.hideNpcViews, npcView)
end

function WorldCombatModule:OnRemoveHideNpcViews(npcView)
  if not self.hideNpcViews then
    self.hideNpcViews = {}
  end
  if not UE.UObject.IsValid(npcView) then
    return
  end
  table.removeValue(self.hideNpcViews, npcView)
end

function WorldCombatModule:OnGetHideNpcViews()
  if not self.hideNpcViews then
    self.hideNpcViews = {}
  end
  return self.hideNpcViews
end

function WorldCombatModule:OnMiniGameExit()
  self.hideNpcViews = {}
end

return WorldCombatModule

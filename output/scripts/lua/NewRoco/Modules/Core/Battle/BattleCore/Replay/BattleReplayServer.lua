local ProtoCMD = require("Data.PB.ProtoCMD")
local BattlePerformEvent = require("NewRoco.Modules.Core.Battle.BattleCore.BattlePerformEvent")
local BattleEvent = require("NewRoco.Modules.Core.Battle.Common.BattleEvent")
local BattleConst = require("NewRoco.Modules.Core.Battle.Common.BattleConst")
local BattleUtils = require("NewRoco.Modules.Core.Battle.Common.BattleUtils")
local BattleReplayServer = NRCClass()

function BattleReplayServer:Start()
  self.cmdHandlerDict = {
    [ProtoCMD.ZoneSvrCmd.ZONE_BATTLE_ENTER_NOTIFY] = _G.BattleNetManager.ZoneBattleEnterNotify,
    [ProtoCMD.ZoneSvrCmd.ZONE_BATTLE_PRE_PLAY_NOTIFY] = _G.BattleNetManager.ZoneBattlePrePlayNotify,
    [ProtoCMD.ZoneSvrCmd.ZONE_BATTLE_LOAD_FINISH_NOTIFY] = _G.BattleNetManager.BattleLoadFinishNotify,
    [ProtoCMD.ZoneSvrCmd.ZONE_BATTLE_ROUND_START_NOTIFY] = _G.BattleNetManager.ZoneBattleRoundStartNotify,
    [ProtoCMD.ZoneSvrCmd.ZONE_BATTLE_CMD_SYNC_NOTIFY] = _G.BattleNetManager.ZoneBattleCmdSyncNotify,
    [ProtoCMD.ZoneSvrCmd.ZONE_BATTLE_PERFORM_START_NOTIFY] = _G.BattleNetManager.ZoneBattlePerformStartNotify,
    [ProtoCMD.ZoneSvrCmd.ZONE_BATTLE_INSTANT_PERFORM_NOTIFY] = _G.BattleNetManager.ZoneBattleInstantPerformNotify,
    [ProtoCMD.ZoneSvrCmd.ZONE_BATTLE_CHANGE_AUTO_CMD_NOTIFY] = _G.BattleNetManager.BattleChangeAutoCmdNotify,
    [ProtoCMD.ZoneSvrCmd.ZONE_BATTLE_FINISH_NOTIFY] = _G.BattleNetManager.ZoneBattleFinishNotify,
    [ProtoCMD.ZoneSvrCmd.ZONE_BATTLE_AI_SELECT_SKILL_NOTIFY] = _G.BattleNetManager.ZoneBattleAiSelectSkillNotify,
    [ProtoCMD.ZoneSvrCmd.ZONE_BATTLE_PVP_PERFORM_START_NOTIFY] = _G.BattleNetManager.ZoneBattlePvpPerformStartNotify,
    [ProtoCMD.ZoneSvrCmd.ZONE_BATTLE_ROLE_LEAVE_NOTIFY] = _G.BattleNetManager.BattlePlayerLeaveNotify
  }
  _G.BattleEventCenter:Bind(self, BattlePerformEvent.TurnPlayComplete, BattleEvent.Replay_Pause, BattleEvent.Replay_Resume, BattleEvent.Replay_Fast, BattleEvent.Replay_Slow, BattleEvent.Replay_Redo, BattleEvent.Replay_Undo, BattleEvent.Replay_RefreshRoundIdx, BattleEvent.Replay_Exit)
  self:ResetReplaySettings()
end

function BattleReplayServer:Stop()
  _G.BattleEventCenter:UnBind(self)
end

function BattleReplayServer:OnReplayExit()
  if _G.BattleManager.stateFsm then
    _G.BattleManager.stateFsm:SendEvent(BattleEvent.EnterNormalOver)
  end
  self:ResetReplaySettings()
  _G.BattleReplayManager:ResetClientEnv()
  self:Stop()
end

function BattleReplayServer:OnReplayPause()
  self.IsPaused = true
end

function BattleReplayServer:OnReplayResume()
  self.IsPaused = false
  self:TryResume()
end

function BattleReplayServer:OnReplayFast()
  if self.IsSpeedy then
    if self.FastBulletTimeId and self.FastBulletTimeId > 0 then
      _G.BattleBulletTimeManager:LeaveBulletTime(self.FastBulletTimeId)
      self.FastBulletTimeId = -1
    end
  else
    if self.SlowBulletTimeId and self.SlowBulletTimeId > 0 then
      _G.BattleBulletTimeManager:LeaveBulletTime(self.SlowBulletTimeId)
      self.SlowBulletTimeId = -1
    end
    self.FastBulletTimeId = _G.BattleBulletTimeManager:EnterBulletTime(UE.EBulletTimeType.ActionPerform, UE.EBulletTimeChangeType.Change, _G.UE4Helper.GetCurrentWorld(), BattleConst.Replay.ReplaySpeedFast, UE.EBulletTimeChangeType.None, {}, 1)
  end
  self.IsSpeedy = not self.IsSpeedy
end

function BattleReplayServer:OnReplaySlow()
  if self.IsSpeedy then
    if self.SlowBulletTimeId and self.SlowBulletTimeId > 0 then
      _G.BattleBulletTimeManager:LeaveBulletTime(self.SlowBulletTimeId)
      self.SlowBulletTimeId = -1
    end
  else
    if self.FastBulletTimeId and self.FastBulletTimeId > 0 then
      _G.BattleBulletTimeManager:LeaveBulletTime(self.FastBulletTimeId)
      self.FastBulletTimeId = -1
    end
    self.SlowBulletTimeId = _G.BattleBulletTimeManager:EnterBulletTime(UE.EBulletTimeType.ActionPerform, UE.EBulletTimeChangeType.Change, _G.UE4Helper.GetCurrentWorld(), BattleConst.Replay.ReplaySpeedSlow, UE.EBulletTimeChangeType.None, {}, 1)
  end
  self.IsSpeedy = not self.IsSpeedy
end

function BattleReplayServer:OnRefreshRoundIdxMain(roundIdx)
  _G.BattleReplayManager.replayTargetRound = roundIdx
  _G.BattleEventCenter:Dispatch(BattleEvent.Replay_RefreshRoundIdxUI, _G.BattleReplayManager.replayTargetRound)
end

function BattleReplayServer:OnReplayRoundUndo()
  local targetRound = _G.BattleReplayManager.replayTargetRound - 1
  if targetRound < 0 then
    return
  else
    local isValid = true
    if 0 == targetRound then
      local preplayNotifyIdx = _G.BattleReplayCachePool.preNotifyIdx or 0
      if preplayNotifyIdx > 0 then
        self.notifyIdx = preplayNotifyIdx
      else
        isValid = false
        Log.Error("No preplay notify found!")
      end
    else
      self.notifyIdx = _G.BattleReplayCachePool.roundStartHeadDict[targetRound]
    end
    if isValid then
      _G.BattleReplayManager.replayTargetRound = targetRound
      _G.BattleEventCenter:Dispatch(BattleEvent.Replay_RefreshRoundIdxUI, _G.BattleReplayManager.replayTargetRound)
    end
  end
end

function BattleReplayServer:OnReplayRoundRedo()
  local targetRound = _G.BattleReplayManager.replayTargetRound + 1
  if not self.notifyRoundNum or targetRound > self.notifyRoundNum then
    return
  else
    _G.BattleReplayManager.replayTargetRound = targetRound
    _G.BattleEventCenter:Dispatch(BattleEvent.Replay_RefreshRoundIdxUI, _G.BattleReplayManager.replayTargetRound)
    self.notifyIdx = _G.BattleReplayCachePool.roundStartHeadDict[targetRound]
  end
end

function BattleReplayServer:OnBattleEvent(battleEvent, ...)
  Log.Debug("BattleReplayServer:OnBattleEvent ", battleEvent, _G.BattleManager.battleRuntimeData:IsInReplayMode())
  if not _G.BattleManager.battleRuntimeData:IsInReplayMode() then
    return
  end
  if battleEvent == BattlePerformEvent.TurnPlayComplete then
    Log.Debug("BattleEventCenter onbattleevent:BattlePerformEvent.TurnPlayComplete:", _G.BattleManager:GetCurRound())
    if not self.IsPaused then
      self:PlayNextNotify()
    else
      self.IsReceivedTurnEnd = true
    end
    return true
  elseif battleEvent == BattleEvent.Replay_Pause then
    self:OnReplayPause()
    return true
  elseif battleEvent == BattleEvent.Replay_Resume then
    self:OnReplayResume()
    return true
  elseif battleEvent == BattleEvent.Replay_Fast then
    self:OnReplayFast()
    return true
  elseif battleEvent == BattleEvent.Replay_Slow then
    self:OnReplaySlow()
    return true
  elseif battleEvent == BattleEvent.Replay_Redo then
    self:OnReplayRoundRedo()
    return true
  elseif battleEvent == BattleEvent.Replay_Undo then
    self:OnReplayRoundUndo()
    return true
  elseif battleEvent == BattleEvent.Replay_RefreshRoundIdx then
    self:OnRefreshRoundIdxMain(...)
    return true
  elseif battleEvent == BattleEvent.Replay_Exit then
    self:OnReplayExit()
    return true
  end
end

function BattleReplayServer:TryResume()
  if self.IsReceivedTurnEnd and not self.IsPaused then
    self.IsReceivedTurnEnd = false
    self:PlayNextNotify()
  end
end

function BattleReplayServer:PlayNextNotify()
  if self.notifyIdx <= self.notifyNum and _G.BattleReplayCachePool.dict and _G.BattleReplayCachePool.dict[self.curBattleID] then
    local struct = _G.BattleReplayCachePool.dict[self.curBattleID][self.notifyIdx]
    self.notifyIdx = self.notifyIdx + 1
    if struct.id == ProtoCMD.ZoneSvrCmd.ZONE_BATTLE_ROUND_START_NOTIFY then
      _G.BattleNetManager:ZoneBattleRoundStartNotify(struct.data)
      if _G.BattleManager:CheckFBSwitchBattleCfg(struct.data) then
        _G.DelayManager:DelaySeconds(10, function()
          self:PlayNextNotify()
        end)
        return
      end
      self:PlayNextNotify()
      return
    elseif struct.id == ProtoCMD.ZoneSvrCmd.ZONE_BATTLE_PERFORM_START_NOTIFY then
      _G.BattleNetManager:ZoneBattlePerformStartNotify(struct.data)
    elseif struct.id == ProtoCMD.ZoneSvrCmd.ZONE_BATTLE_INSTANT_PERFORM_NOTIFY then
      _G.BattleNetManager:ZoneBattleInstantPerformNotify(struct.data)
    elseif struct.id == ProtoCMD.ZoneSvrCmd.ZONE_BATTLE_AI_SELECT_SKILL_NOTIFY then
      _G.BattleNetManager:ZoneBattleAiSelectSkillNotify(struct.data)
      self:PlayNextNotify()
      return
    elseif struct.id == ProtoCMD.ZoneSvrCmd.ZONE_BATTLE_FINISH_NOTIFY then
      _G.BattleNetManager:ZoneBattleFinishNotify(struct.data)
      self:ResetReplaySettings()
      _G.BattleReplayManager:ResetClientEnv()
    elseif struct.id == ProtoCMD.ZoneSvrCmd.ZONE_BATTLE_ENTER_NOTIFY then
      _G.BattleNetManager:ZoneBattleEnterNotify(struct.data)
      self:PlayNextNotify()
    elseif struct.id == ProtoCMD.ZoneSvrCmd.ZONE_BATTLE_PRE_PLAY_NOTIFY then
      local BattleMain = BattleUtils.GetMainWindow()
      if _G.BattleReplayCachePool.ZoneBattleEnterNotify then
        local enterNotify = _G.BattleReplayCachePool.ZoneBattleEnterNotify
        _G.BattleManager.battlePawnManager:RefreshBattleFieldInReplayByEnter(enterNotify.init_info)
      end
      _G.BattleNetManager:ZoneBattlePrePlayNotify(struct.data)
    elseif struct.id == ProtoCMD.ZoneSvrCmd.ZONE_BATTLE_CMD_SYNC_NOTIFY then
      _G.BattleNetManager:ZoneBattleCmdSyncNotify(struct.data)
      self:PlayNextNotify()
      return
    elseif struct.id == ProtoCMD.ZoneSvrCmd.ZONE_BATTLE_CMD_PUSHBACK_RSP then
      _G.BattleEventCenter:Dispatch(BattleEvent.PUSHBACK_CMD_SENT, struct.data)
      _G.DelayManager:DelaySeconds(1, function()
        self:PlayNextNotify()
      end)
      return
    elseif struct.id == ProtoCMD.ZoneSvrCmd.ZONE_BATTLE_ROLE_LEAVE_NOTIFY then
      _G.BattleNetManager:BattlePlayerLeaveNotify(struct.data)
      self:PlayNextNotify()
      return
    else
      self:PlayNextNotify()
    end
  else
    Log.Error("next notify is nil")
    if BattleAutoTest.IsAutoPlayBattleRecords then
      self:OnReplayExit()
    end
  end
end

function BattleReplayServer:ResetReplaySettings()
  self.curBattleID = nil
  self.IsPaused = false
  self.IsReceivedTurnEnd = false
  self.IsInitInBattle = false
  self.IsSpeedy = false
  self.notifyIdx = 3
  self.notifyNum = 0
  _G.UE4.UGameplayStatics.SetGlobalTimeDilation(_G.UE4Helper.GetCurrentWorld(), 1.0)
end

function BattleReplayServer:BattleEnter(battleID)
  local noPreplayNotify = false
  if not self.IsInitInBattle then
    self.BattleManager = _G.BattleManager
    local preplayNotifyIdx = _G.BattleReplayCachePool.preNotifyIdx
    if preplayNotifyIdx > 0 then
      self.notifyIdx = preplayNotifyIdx + 1
    else
      self.notifyIdx = 2
      noPreplayNotify = true
    end
    self.IsInitInBattle = true
  end
  self.curBattleID = battleID
  local battleData = _G.BattleReplayCachePool:GetBattleData(battleID)
  if battleData then
    _G.BattleNetManager.battleServer = self
    Log.Debug("BattleReplayServer BattleEnter:", battleID, #battleData)
    for i = 1, #battleData do
      battleData[i].isRsp = false
    end
    local cmdid = battleData[1].id
    local notify = battleData[1].data
    battleData[1].isRsp = true
    if self.cmdHandlerDict[cmdid] then
      self.cmdHandlerDict[cmdid](_G.BattleNetManager, notify)
    end
    if battleData[2].id == ProtoCMD.ZoneSvrCmd.ZONE_BATTLE_PRE_PLAY_NOTIFY then
      notify = battleData[2].data
      _G.DelayManager:DelaySeconds(3, _G.BattleNetManager.ZoneBattlePrePlayNotify, _G.BattleNetManager, notify)
    end
    self.notifyNum = #battleData
    self.notifyRoundNum = #_G.BattleReplayCachePool.roundStartHeadDict
  end
  if noPreplayNotify then
    self:PlayNextNotify()
  end
end

function BattleReplayServer:PlayRound(roundIdx)
  Log.Debug("BattleReplayServer PlayRound try do:", roundIdx)
  local data = _G.BattleReplayCachePool:GetRoundSyncData(self.curBattleID, roundIdx)
  if data then
    _G.BattleNetManager:ZoneBattleRoundStartNotify(data)
  else
    Log.Error("\230\178\161\230\156\137\230\137\190\229\136\176\228\184\139\228\184\128\228\184\170\229\155\158\229\144\136Start\230\149\176\230\141\174\239\188\140\230\136\152\230\150\151\231\187\147\230\157\159:", roundIdx)
    return false
  end
  local data1 = _G.BattleReplayCachePool:GetRoundData(self.curBattleID, roundIdx)
  if data1 then
    Log.Debug("BattleReplayServer PlayRound:", roundIdx)
    _G.BattleNetManager:ZoneBattlePerformStartNotify(data1)
  else
    Log.Debug("BattleReplayServer PlayRound:fail", roundIdx)
    Log.Error("\230\178\161\230\156\137\230\137\190\229\136\176\228\184\139\228\184\128\228\184\170\229\155\158\229\144\136Perform\230\149\176\230\141\174\239\188\140\230\136\152\230\150\151\231\187\147\230\157\159:", roundIdx)
    return false
  end
  _G.BattleEventCenter:Dispatch(BattleEvent.Replay_RefreshRoundIdxUI, _G.BattleReplayManager.replayTargetRound)
  return true
end

function BattleReplayServer:Send(cmd)
  Log.Debug("BattleReplayServer Send:", cmd)
end

function BattleReplayServer:SendWithHandler(cmd, req, caller, rspHandler)
  Log.Debug("BattleReplayServer SendWithHandler:", cmd)
end

function BattleReplayServer:NextNotifyIsForBeastOrBloodTeamCatch()
  if not BattleUtils.IsBeastTeam() and not BattleUtils.IsBloodTeam() then
    return false
  end
  if self.notifyIdx <= self.notifyNum then
    local nextStruct = _G.BattleReplayCachePool.dict[self.curBattleID][self.notifyIdx]
    if nextStruct.id == ProtoCMD.ZoneSvrCmd.ZONE_BATTLE_INSTANT_PERFORM_NOTIFY then
      return true
    end
    return false
  end
  return false
end

return BattleReplayServer

local BattleUtils = require("NewRoco.Modules.Core.Battle.Common.BattleUtils")
local BattleEvent = require("NewRoco.Modules.Core.Battle.Common.BattleEvent")
local Enum = require("Data.Config.Enum")
local BattleInitAction = BattleActionBase:Extend("BattleInitAction")

function BattleInitAction:Ctor(name, properties)
  BattleActionBase.Ctor(self, name, properties)
  self.BattleManager = _G.BattleManager
end

function BattleInitAction:OnEnter()
  Log.Trace("BattleInitAction:OnEnter")
  NRCEventCenter:DispatchEvent(BattleEvent.EnterBattle)
  self.BattleManager:OpenBattleMainWindow()
  local battleType = _G.BattleManager.battleRuntimeData.battleType
  Log.Debug("BattleInitAction onenter:", battleType)
  if BattleUtils.IsPvp() then
    if self:CheckIsReconnect() or BattleUtils.IsWatchingBattle() then
      self.fsm:SendEvent(BattleEvent.EnterPVPReconnectEnter, self)
    else
      self.fsm:SendEvent(BattleEvent.EnterPVPEnter, self)
    end
  elseif BattleUtils.IsNpcChallenge() then
    if self:CheckIsReconnect() or BattleUtils.IsWatchingBattle() then
      self.fsm:SendEvent(BattleEvent.EnterNpcChallengeReconnectEnter, self)
    else
      self.fsm:SendEvent(BattleEvent.EnterNpcChallengeEnter, self)
    end
  elseif BattleUtils.IsWeeklyChallenge() then
    if self:CheckIsReconnect() or BattleUtils.IsWatchingBattle() then
      self.fsm:SendEvent(BattleEvent.EnterWeeklyChallengeReconnectEnter, self)
    else
      self.fsm:SendEvent(BattleEvent.EnterWeeklyChallengeEnter, self)
    end
  elseif BattleUtils.IsTrainBattle() then
    if self:CheckIsReconnect() or BattleUtils.IsWatchingBattle() then
      self.fsm:SendEvent(BattleEvent.EnterTrainBattleReconnectEnter, self)
    else
      self.fsm:SendEvent(BattleEvent.EnterTrainBattleEnter, self)
    end
  elseif BattleUtils.IsTerritoryTrialBattle() then
    self.fsm:SendEvent(BattleEvent.EnterNearbyReconnectEnter, self)
  elseif battleType == Enum.BattleType.BT_PVESPECIAL then
    if self:CheckIsReconnect() or self:CheckIsDebugConnect() then
      self.fsm:SendEvent(BattleEvent.EnterNearbyReconnectEnter, self)
    else
      Log.Debug("BattleInitAction OnEnter true:", self.BattleManager.battleRuntimeData:GetEnterBattleType())
      self.fsm:SendEvent(BattleEvent.EnterNearbyEnterPVESpecialDelay, self)
    end
  elseif BattleUtils.IsLeaderFight() or BattleUtils.IsWorldLeaderFight() or BattleUtils.IsLeaderChallenge() then
    if self:CheckIsReconnect() or self:CheckIsDebugConnect() then
      self.fsm:SendEvent(BattleEvent.EnterLeaderReconnectEnter, self)
    else
      Log.Debug("BattleInitAction onenter leader fight")
      self.fsm:SendEvent(BattleEvent.EnterLeaderEnter, self)
    end
  elseif BattleUtils.IsBloodTeam() then
    if self:CheckIsReconnect() or BattleUtils.IsWatchingBattle() then
      self.fsm:SendEvent(BattleEvent.EnterTeamBloodReconnect, self)
    else
      self.fsm:SendEvent(BattleEvent.EnterTeamBlood, self)
    end
  elseif BattleUtils.IsBeastTeam() then
    if self:CheckIsReconnect() then
      self.fsm:SendEvent(BattleEvent.EnterTeamBeastReconnect, self)
    else
      self.fsm:SendEvent(BattleEvent.EnterTeamBeast, self)
    end
  elseif BattleUtils.IsFinalBattleP1() then
    if self:CheckIsReconnect() then
      self.fsm:SendEvent(BattleEvent.EnterFinalBattleReconnect, self)
    else
      self.fsm:SendEvent(BattleEvent.EnterFinalBattle, self)
    end
  elseif BattleUtils.IsB1FinalBattleP1() then
    if self:CheckIsReconnect() then
      self.fsm:SendEvent(BattleEvent.EnterB1FinalBattleReconnect, self)
    else
      self.fsm:SendEvent(BattleEvent.EnterB1FinalBattle, self)
    end
  elseif self:CheckIsReconnect() or self:CheckIsDebugConnect() or BattleUtils.IsWatchingBattle() then
    self.fsm:SendEvent(BattleEvent.EnterNearbyReconnectEnter, self)
  else
    Log.Debug("BattleInitAction OnEnter true:", self.BattleManager.battleRuntimeData:GetEnterBattleType())
    if not BattleUtils.HasEnemyPlayer() then
      self.fsm:SendEvent(BattleEvent.EnterNearbyEnter, self)
    else
      self.fsm:SendEvent(BattleEvent.EnterNearbyEnterPVE, self)
    end
  end
  self:Finish()
end

function BattleInitAction:CheckIsReconnect()
  if self.BattleManager.battleRuntimeData.battleStartParam:IsReconnect() then
    local showTip = _G.DataConfigManager:GetLocalizationConf("Reconnect_Battle_Tips").msg
    _G.NRCModuleManager:DoCmd(TipsModuleCmd.TopHud_ShowTips, showTip)
    return true
  end
  return false
end

function BattleInitAction:CheckIsDebugConnect()
  if _G.IsEnterBattleByDebug then
    return false
  end
  if not self.BattleManager.battleRuntimeData:HasValidNPC() then
    return true
  end
  return false
end

function BattleInitAction:OnExit()
  self.BattleManager = nil
  self.preLoadAssetNumber = 0
end

return BattleInitAction
